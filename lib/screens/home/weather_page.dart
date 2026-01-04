import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/weather_model.dart';
import '../../services/weather_service.dart';
import '../../providers/settings_provider.dart';
import '../settings/settings_page.dart';
import '../../utils/weather_utils.dart';
import '../../widgets/current_weather_card.dart';
import '../../widgets/daily_forecast_item.dart';
import '../../widgets/details_popup.dart';
import '../../widgets/hourly_forecast_list.dart';
import '../map_picker_page.dart';

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
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastCityAndFetch();
  }

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

    String? savedCity = prefs.getString('last_city');
    if (savedCity != null && savedCity.isNotEmpty) {
      _fetchWeather(savedCity);
    } else {
      String currentCity = await _weatherService.getCurrentCity();
      _fetchWeather(currentCity);
    }
  }


  Future<void> _fetchWeatherByCoordinates(double lat, double lon) async {
    setState(() => _isLoading = true);
    final lang = Provider.of<SettingsProvider>(context, listen: false).language;

    try {
      final weather = await _weatherService.getWeatherByCoordinates(lat, lon, lang: lang);

      final forecastResult = await _weatherService.getComprehensiveForecastByCoordinates(lat, lon, lang: lang);

      setState(() {
        _weather = weather;
        _forecast = forecastResult.daily;   // قائمة الأيام
        _hourlyForecast = forecastResult.hourly; // قائمة الساعات
        _isLoading = false;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('last_city', weather.cityName);

    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching weather by coords: $e");
    }
  }

  Future<void> _fetchWeather(String cityName) async {
    setState(() => _isLoading = true);
    final lang = Provider.of<SettingsProvider>(context, listen: false).language;

    try {
      final weather = await _weatherService.getWeather(cityName, lang: lang);

      final forecastResult = await _weatherService.getComprehensiveForecast(cityName, lang: lang);

      setState(() {
        _weather = weather;
        _forecast = forecastResult.daily;
        _hourlyForecast = forecastResult.hourly;
        _isLoading = false;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('last_city', cityName);
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching weather: $e");
    }
  }

  void _showCitySearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Search City"),
        content: TextField(
          controller: _cityController,
          decoration: const InputDecoration(hintText: "Enter city name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_cityController.text.isNotEmpty) {
                _fetchWeather(_cityController.text);
                _cityController.clear();
              }
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // زر "موقعي" (GPS)
        leading: IconButton(
          icon: const Icon(Icons.my_location, color: Colors.white),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.remove('last_city');
            prefs.remove('last_source');

            setState(() => _isLoading = true);
            try {
              String currentCity = await _weatherService.getCurrentCity();
              _fetchWeather(currentCity);
            } catch (e) {
              setState(() => _isLoading = false);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()))
                  .then((_) => _loadLastCityAndFetch());
            },
          ),

          // زر الخريطة الجديد
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const MapPickerPage()),
              );

              // معالجة النتيجة عند العودة
              if (result != null) {
                final double lat = result['lat'];
                final double lon = result['lon'];
                final String? cityName = result['city'];

                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('last_lat', lat);
                await prefs.setDouble('last_lon', lon);
                await prefs.setString('last_source', 'coords');

                await _fetchWeatherByCoordinates(lat, lon);

                // تحديث اسم المدينة يدوياً إذا توفر من الخريطة
                if (cityName != null && mounted) {
                  setState(() {
                    _weather = _weather?.copyWith(cityName: cityName);
                  });
                }
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: _showCitySearchDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // الخلفية
          Container(
            decoration: BoxDecoration(
              gradient: WeatherUtils.getBackgroundGradient(_weather?.mainCondition),
            ),
          ),

          // أنيميشن الخلفية
          if (settings.isDynamicBackground && _weather != null)
            Positioned.fill(
              child: Lottie.asset(
                WeatherUtils.getDynamicBackgroundAnimation(_weather)!,
                fit: BoxFit.cover,
              ),
            ),

          // المحتوى الرئيسي
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RefreshIndicator(
              color: Colors.white,
              onRefresh: () async { await _loadLastCityAndFetch(); },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // البطاقة الرئيسية
                      if (_weather != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: CurrentWeatherCard(
                            weather: _weather!,
                            onTap: () {
                              bool isGlass = settings.enableGlassmorphism || settings.isDarkMode;
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => DetailsPopup(weather: _weather!, isCurrent: true, date: DateTime.now(), isGlass: isGlass),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 30),

                      // توقعات الساعات (باستخدام الويدجت المنظم)
                      if (_hourlyForecast != null && _hourlyForecast!.isNotEmpty)
                        HourlyForecastList(
                          hourlyForecast: _hourlyForecast!,
                          onHourTap: (hour, date) {
                            bool isGlass = settings.enableGlassmorphism || settings.isDarkMode;
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => DetailsPopup(
                                weather: hour,
                                isCurrent: false,
                                date: date,
                                isGlass: isGlass,
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 30),

                      // توقعات الأيام
                      if (_forecast != null && _forecast!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settings.language == 'ar' ? "الأيام القادمة" : "DAILY FORECAST",
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 15),

                              ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _forecast!.length,
                                itemBuilder: (context, index) {
                                  final date = DateTime.now().add(Duration(days: index + 1));
                                  return DailyForecastItem(
                                    day: _forecast![index],
                                    index: index,
                                    onTap: () {
                                      bool isGlass = settings.enableGlassmorphism || settings.isDarkMode;
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        isScrollControlled: true,
                                        builder: (context) => DetailsPopup(
                                          weather: _forecast![index],
                                          isCurrent: false,
                                          date: date,
                                          isGlass: isGlass,
                                        ),
                                      );
                                    },
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
    );
  }
}
