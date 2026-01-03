import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../settings/settings_page.dart';
import 'dart:ui'; // مهمة جداً للتأثير الزجاجي (BackdropFilter)
import '../map_picker_page.dart';
import '../../utils/weather_utils.dart';


class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService();
  WeatherModel? _weather;
  List<WeatherModel>? _forecast;
  List<WeatherModel>? _hourlyForecast;
  bool _isLoading = true;
  final TextEditingController _cityController = TextEditingController(); // للتحكم في نص البحث


  @override
  void initState() {
    super.initState();
    _loadLastCityAndFetch(); // نبدأ بتحميل آخر مدينة محفوظة أو الـ GPS
  }
  Future<void> _fetchWeatherByCoordinates(double lat, double lon) async {
    setState(() => _isLoading = true);

    final lang = Provider.of<SettingsProvider>(context, listen: false).language;

    try {
      final weather =
      await _weatherService.getWeatherByCoordinates(lat, lon, lang: lang);
      final forecast =
      await _weatherService.getForecastByCoordinates(lat, lon, lang: lang);
      final hourly =
      await _weatherService.getHourlyByCoordinates(lat, lon, lang: lang);

      setState(() {
        _weather = weather;
        _forecast = forecast;
        _hourlyForecast = hourly;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }


  // دالة جديدة: تقرر هل نستخدم آخر مدينة محفوظة أم الـ GPS
  Future<void> _loadLastCityAndFetch() async {
    final prefs = await SharedPreferences.getInstance();

    final source = prefs.getString('last_source');

    if (source == 'coords') {
      final lat = prefs.getDouble('last_lat');
      final lon = prefs.getDouble('last_lon');

      if (lat != null && lon != null) {
        await _fetchWeatherByCoordinates(lat, lon);
        return;
      }
    }

    // fallback to city name
    final savedCity = prefs.getString('last_city');
    if (savedCity != null && savedCity.isNotEmpty) {
      await _fetchWeather(savedCity);
      return;
    }

    // fallback to GPS
    final currentCity = await _weatherService.getCurrentCity();
    await _fetchWeather(currentCity);
  }


  // تعديل دالة جلب الطقس لتقبل اسم مدينة محدد
  Future<void> _fetchWeather(String cityName) async {
    setState(() => _isLoading = true);
    final lang = Provider.of<SettingsProvider>(context, listen: false).language;

    try {
      final weather = await _weatherService.getWeather(cityName, lang: lang);
      final forecast = await _weatherService.getForecast(cityName, lang: lang);
      final hourlyForecast = await _weatherService.getHourlyForecast(cityName, lang: lang);

      setState(() {
        _weather = weather;
        _forecast = forecast;
        _hourlyForecast = hourlyForecast;
        _isLoading = false;
      });

      // حفظ اسم المدينة الناجحة في الذاكرة
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city', cityName);
    } catch (e) {
      // في حال الخطأ (مثلا اسم مدينة خاطئ)، أوقف التحميل وأظهر تنبيهاً بسيطاً
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("لم يتم العثور على المدينة، تأكد من الاسم")),
      );
    }
  }
  Color _getButtonBackground(String? condition) {
    if (condition == null) {
      return Colors.blue.shade400;
    }

    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.orange.shade500; // close to sky
      case 'clouds':
        return Colors.grey.shade600;
      case 'rain':
        return Colors.blueGrey.shade600;
      case 'thunderstorm':
        return Colors.deepPurple.shade400;
      default:
        return Colors.blue.shade500;
    }
  }


  void _showDailyDetails(BuildContext context, WeatherModel day, bool isGlass, DateTime date) {
    final lang = Provider.of<SettingsProvider>(context, listen: false).language;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isGlass ? Colors.black.withOpacity(0.6) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              if (!isGlass)
                const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 5)
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: isGlass ? 10 : 0, sigmaY: isGlass ? 10 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(
                  DateFormat('EEEE, d MMMM', lang).format(date),
                  style: TextStyle(color: isGlass ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  day.description,
                  style: TextStyle(color: isGlass ? Colors.white70 : Colors.grey[700], fontSize: 18),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem(Icons.thermostat, "${day.temperature.round()}°C", "الحرارة", isGlass),
                    _buildDetailItem(Icons.water_drop, "${day.humidity}%", "الرطوبة", isGlass),
                    _buildDetailItem(Icons.air, "${day.windSpeed} km/h", "الرياح", isGlass),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrentDetails(BuildContext context, bool isGlass) {
    if (_weather == null) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isArabic = settings.language == 'ar';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isGlass ? Colors.black.withOpacity(0.6) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              if (!isGlass)
                const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 5)
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: isGlass ? 10 : 0, sigmaY: isGlass ? 10 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(
                  isArabic ? "تفاصيل الطقس الحالية" : "Current Details",
                  style: TextStyle(color: isGlass ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem(Icons.water_drop, "${_weather!.humidity}%", isArabic ? "الرطوبة" : "Humidity", isGlass),
                    _buildDetailItem(Icons.air, "${_weather!.windSpeed} km/h", isArabic ? "الرياح" : "Wind", isGlass),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem(Icons.wb_sunny, DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(_weather!.sunrise * 1000)), isArabic ? "الشروق" : "Sunrise", isGlass),
                    _buildDetailItem(Icons.nights_stay, DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(_weather!.sunset * 1000)), isArabic ? "الغروب" : "Sunset", isGlass),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label, bool isDarkInfo) {
    Color color = isDarkInfo ? Colors.white : Colors.black;
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 14)),
      ],
    );
  }

  // دالة إظهار نافذة البحث
  void _showCitySearchDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("بحث عن مدينة"),
            content: TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                  hintText: "ادخل اسم المدينة (English)"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              TextButton(
                onPressed: () {
                  if (_cityController.text.isNotEmpty) {
                    Navigator.pop(context);
                    _fetchWeather(
                        _cityController.text); // ابحث عن المدينة الجديدة
                    _cityController.clear();
                  }
                },
                child: const Text("بحث"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      // شريط العنوان وأزرار البحث (كما هي)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // ننتقل للإعدادات، وعند العودة نحدث البيانات (لتطبيق تغيير اللغة)
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()))
                  .then((_) => _loadLastCityAndFetch());
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: _showCitySearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const MapPickerPage()),
              );

              if (result != null) {
                final double lat = result['lat'];
                final double lon = result['lon'];
                final String? cityName = result['city'];

                // 🔐 Save coordinates as last source
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('last_lat', lat);
                await prefs.setDouble('last_lon', lon);
                await prefs.setString('last_source', 'coords');




                await _fetchWeatherByCoordinates(lat, lon);

                if (cityName != null && mounted) {
                  setState(() {
                    _weather = _weather?.copyWith(cityName: cityName);
                  });
                }
              }


            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,


      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: WeatherUtils.getBackgroundGradient(_weather?.mainCondition),
            ),
          ),

          if (settings.isDynamicBackground && _weather != null)
             Positioned.fill(
               child: Builder(
                 builder: (context) {
                   String? animFile = WeatherUtils.getDynamicBackgroundAnimation(_weather);

                   if (animFile == null) return const SizedBox();

                   return Lottie.asset(
                     animFile,
                     fit: BoxFit.cover,
                     errorBuilder: (context, error, stackTrace) {
                       return const SizedBox();
                     },
                   );
                 },
               ),
             ),

          SafeArea(
            child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
              color: Colors.white,
              backgroundColor: Colors.blue.withOpacity(0.5),
              onRefresh: () async {
                await _loadLastCityAndFetch();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          bool isGlassMode = settings.enableGlassmorphism || settings.isDarkMode;
                          _showCurrentDetails(context, isGlassMode);
                        },
                        child: Builder(
                          builder: (context) {
                            Widget mainCard = Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white, size: 24),
                                      const SizedBox(width: 5),
                                      Text(
                                        _weather?.cityName.toUpperCase() ?? "",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      DateFormat('EEEE, d MMMM | hh:mm a', settings.language).format(DateTime.now()),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Lottie.asset(
                                    WeatherUtils.getWeatherAnimation(_weather?.mainCondition),
                                    height: 150,
                                  ),
                                  Text(
                                    settings.isCelsius
                                        ? '${_weather?.temperature.round()}°C'
                                        : '${(_weather?.temperature != null ? _weather!.temperature * 9 / 5 + 32 : 0).round()}°F',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 65,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _weather?.mainCondition ?? "",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Icon(Icons.keyboard_arrow_up, color: Colors.white.withOpacity(0.5), size: 24),
                                ],
                              ),
                            );

                            if (settings.enableGlassmorphism) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: mainCard,
                                ),
                              );
                            } else {
                              return mainCard;
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                  // --- Hourly Forecast ---
                  if (_hourlyForecast != null && _hourlyForecast!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(settings.language == 'ar' ? "توقعات الساعات القادمة" : "HOURLY FORECAST", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _hourlyForecast!.length,
                            itemBuilder: (context, index) {
                              final hour = _hourlyForecast![index];
                              return GestureDetector(
                                onTap: () => _showDailyDetails(context, hour, settings.enableGlassmorphism, DateTime.now().add(Duration(hours: (index + 1) * 3))),
                                child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                   border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                     Text(DateFormat('ha').format(DateTime.now().add(Duration(hours: index * 3))), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    Lottie.asset(WeatherUtils.getWeatherAnimation(hour.mainCondition), height: 40),
                                    Text('${hour.temperature.round()}°', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                   const SizedBox(height: 30),
                  // --- Daily Forecast ---
                  if (_forecast != null && _forecast!.isNotEmpty)
                    Padding(
                      // تعديل 1: إضافة مسافة سفلية لتجنب الالتصاق بأسفل الشاشة
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // تعديل 2: إعادة حجم الخط ليكون متناسقاً
                          Text(
                              settings.language == 'ar' ? "الأيام القادمة" : "DAILY FORECAST",
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                          ),

                          // تعديل 3: إضافة مسافة ضرورية بين العنوان والقائمة
                          const SizedBox(height: 10),

                          ListView.builder(
                            padding: EdgeInsets.zero, // <--- أضف هذا السطر لإلغاء الحواف الافتراضية
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _forecast!.length,
                            itemBuilder: (context, index) {
                              final day = _forecast![index];
                              final date = DateTime.now().add(Duration(days: index + 1));
                              return GestureDetector(
                                onTap: () => _showDailyDetails(context, day, settings.enableGlassmorphism, date),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), // زيادة الحشوة الرأسية قليلاً
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // اسم اليوم
                                      Expanded(
                                        child: Text(
                                          DateFormat('EEEE', settings.language).format(date),
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // الحرارة والأيقونة
                                      Row(
                                        mainAxisSize: MainAxisSize.min, // مهم جداً: يأخذ أقل مساحة ممكنة
                                        children: [
                                          // --- التعديل الجذري هنا ---
                                          // تحديد العرض والارتفاع معاً لمنع التمدد
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Lottie.asset(
                                                WeatherUtils.getWeatherAnimation(day.mainCondition),
                                                fit: BoxFit.contain // احتواء الصورة داخل المربع
                                            ),
                                          ),
                                          // -------------------------

                                          const SizedBox(width: 10),
                                          Text('${day.temperature.round()}°', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _getButtonBackground(_weather?.mainCondition),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 4,
        child: const Icon(Icons.my_location, color: Colors.white),
        onPressed: () async {
          setState(() => _isLoading = true);

          try {
            SharedPreferences prefs =
            await SharedPreferences.getInstance();
            await prefs.remove('last_city');

            String currentCity =
            await _weatherService.getCurrentCity();
            await _fetchWeather(currentCity);
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("فشل تحديد الموقع الحالي")),
            );
          }
        },
      ),


    );
  }


}
