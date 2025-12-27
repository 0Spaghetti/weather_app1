import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'settings_page.dart';
import 'dart:ui'; // مهمة جداً للتأثير الزجاجي (BackdropFilter)

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService();
  List<WeatherModel>? _hourlyForecast; // قائمة الساعات

  WeatherModel? _weather;
  List<WeatherModel>? _forecast;
  bool _isLoading = true;
  final TextEditingController _cityController = TextEditingController(); // للتحكم في نص البحث

  @override
  void initState() {
    super.initState();
    _loadLastCityAndFetch(); // نبدأ بتحميل آخر مدينة محفوظة أو الـ GPS
  }

  // دالة جديدة: تقرر هل نستخدم آخر مدينة محفوظة أم الـ GPS
  Future<void> _loadLastCityAndFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedCity = prefs.getString('last_city');

    if (savedCity != null && savedCity.isNotEmpty) {
      await _fetchWeather(savedCity); // حمل المدينة المحفوظة
    } else {
      // إذا لم توجد مدينة محفوظة، استخدم الـ GPS
      String currentCity = await _weatherService.getCurrentCity();
      await _fetchWeather(currentCity);
    }
  }

  // تعديل دالة جلب الطقس لتقبل اسم مدينة محدد
  Future<void> _fetchWeather(String cityName) async {
    setState(() => _isLoading = true);
    final lang = Provider.of<SettingsProvider>(context, listen: false).language;

    try {
      final weather = await _weatherService.getWeather(cityName, lang: lang);
      final forecast = await _weatherService.getForecast(cityName, lang: lang);
      final hourly = await _weatherService.getHourlyForecast(cityName, lang: lang);

      setState(() {
        _weather = weather;
        _forecast = forecast;
        _hourlyForecast = hourly;
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
// دالة لإظهار تفاصيل اليوم في نافذة سفلية
  void _showDailyDetails(BuildContext context, WeatherModel day, bool isGlass, DateTime date) {

    final lang = Provider.of<SettingsProvider>(context, listen: false).language;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // خلفية شفافة لتطبيق التصميم الخاص بنا
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // لون الخلفية يعتمد على الوضع (زجاجي أو عادي)
            color: isGlass ? Colors.black.withOpacity(0.6) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            // تأثير ضبابي للخلفية (Blur)
            boxShadow: [
              if (!isGlass)
                const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 5)
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: isGlass ? 10 : 0, sigmaY: isGlass ? 10 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // يأخذ حجم المحتوى فقط
              children: [
                // خط صغير في الأعلى للسحب
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),

                // العنوان: اسم اليوم
                Text(
                  DateFormat('EEEE, d MMMM', lang).format(date),
                  style: TextStyle(color: isGlass ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // الوصف (مثلاً: أمطار خفيفة)
                Text(
                  day.description,
                  style: TextStyle(color: isGlass ? Colors.white70 : Colors.grey[700], fontSize: 18),
                ),

                const SizedBox(height: 30),

                // صف التفاصيل (الحرارة، الرياح، الرطوبة)
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

  // عنصر مساعد لبناء أيقونة التفاصيل
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

  // دالة الألوان
  LinearGradient _getBackgroundGradient(String? mainCondition) {
    if (mainCondition == null)
      return const LinearGradient(colors: [Colors.blue, Colors.lightBlue]);
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return LinearGradient(
            colors: [Colors.grey.shade800, Colors.grey.shade500],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case 'rain':
        return LinearGradient(
            colors: [Colors.grey.shade900, Colors.blueGrey.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case 'clear':
        return LinearGradient(
            colors: [Colors.orange.shade400, Colors.blue.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      default:
        return const LinearGradient(colors: [Colors.blue, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
    }
  }

// دالة لتحديد ملف الأنيميشن المناسب
  String _getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'lib/assets/sunny.json'; // القيمة الافتراضية

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'lib/assets/cloud.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'lib/assets/rain.json';
      case 'thunderstorm':
        return 'lib/assets/thunder.json';
      case 'clear':
        return 'lib/assets/sunny.json';
      default:
        return 'lib/assets/sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {

    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      // شريط العنوان وأزرار البحث (كما هي)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.my_location, color: Colors.white),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.remove('last_city');
            String currentCity = await _weatherService.getCurrentCity();
            _fetchWeather(currentCity);
          },
        ),
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
        ],
      ),
      extendBodyBehindAppBar: true,

      body: Container(
        decoration: BoxDecoration(
          gradient: _getBackgroundGradient(_weather?.mainCondition),
        ),
        // --- 1. ميزة سحب للتحديث (Pull to Refresh) ---
        child: RefreshIndicator(
          color: Colors.white, // لون دائرة التحميل
          backgroundColor: Colors.blue.withOpacity(0.5),
          onRefresh: () async {
            // عند السحب، نقوم بإعادة تحميل البيانات لنفس المدينة
            await _loadLastCityAndFetch();
          },
          // نستخدم SingleChildScrollView لجعل الشاشة قابلة للسحب دائماً
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 20), // مسافة من الأعلى (عشان الـ AppBar) ومن الأسفل
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // المحتوى السابق
                  const Icon(
                      Icons.location_on, color: Colors.white, size: 30),
                  const SizedBox(height: 10),

                  Text(
                    _weather?.cityName.toUpperCase() ?? "",
                    style: const TextStyle(color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),

                  // --- 2. ميزة التاريخ والوقت ---
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy | hh:mm a', settings.language).format(DateTime.now()), // استخدام settings.language                          DateTime.now()),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16),
                  ),
                  // -----------------------------

                  const SizedBox(height: 40),

                  const SizedBox(height: 20),

                  // --- بطاقة الطقس الحالية الموحدة (أنيميشن + حرارة + وصف) ---
                  Builder(
                    builder: (context) {
                      Widget mainCard = Container(
                        width: double.infinity, // البطاقة تأخذ العرض المتاح
                        margin: const EdgeInsets.symmetric(horizontal: 20), // هوامش جانبية لكي لا تلتصق بالحواف
                        padding: const EdgeInsets.symmetric(vertical: 20), // مساحة داخلية
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15), // لون خلفية شفاف
                          borderRadius: BorderRadius.circular(30), // زوايا دائرية ناعمة
                          border: Border.all(color: Colors.white.withOpacity(0.2)), // حدود بيضاء خفيفة
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // الصندوق يأخذ حجم محتوياته فقط
                          children: [
                            // 1. الأنيميشن (أصبح الآن داخل الصندوق)
                            Lottie.asset(
                              _getWeatherAnimation(_weather?.mainCondition),
                              height: 160, // تصغير الحجم قليلاً ليناسب البطاقة
                            ),

                            const SizedBox(height: 10),

                            // 2. درجة الحرارة
                            Text(
                              settings.isCelsius
                                  ? '${_weather?.temperature.round()}°C'
                                  : '${(_weather!.temperature * 9 / 5 + 32).round()}°F',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 70, // خط كبير وواضح
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // 3. حالة الطقس (مثل Clear, Rain)
                            Text(
                              _weather?.mainCondition ?? "",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );

                      // تطبيق تأثير الزجاج إذا كان مفعلاً
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
                  const SizedBox(height: 30),

                  // قسم الرطوبة والرياح (الذي أضفناه سابقاً)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.white),
                          const Text("الرطوبة",
                              style: TextStyle(color: Colors.white70)),
                          Text("${_weather?.humidity}%",
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.air, color: Colors.white),
                          const Text("الرياح",
                              style: TextStyle(color: Colors.white70)),
                          Text("${_weather?.windSpeed} km/h",
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),

                  if (settings.showSunDetails && _weather != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(children: [
                          const Icon(Icons.wb_sunny, color: Colors.yellow),
                          Text(DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(_weather!.sunrise * 1000)), style: const TextStyle(color: Colors.white)),
                          const Text("الشروق", style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ]),
                        Column(children: [
                          const Icon(Icons.nights_stay, color: Colors.orange),
                          Text(DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(_weather!.sunset * 1000)), style: const TextStyle(color: Colors.white)),
                          const Text("الغروب", style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ]),
                      ],
                    )
                  ],

                  const SizedBox(height: 30),
                  // --- قسم توقعات الساعات (الجديد) ---
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("خلال 24 ساعة", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 100, // ارتفاع أقل قليلاً من القائمة السفلية
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _hourlyForecast?.length ?? 0,
                      itemBuilder: (context, index) {
                        final hourWeather = _hourlyForecast![index];
                        // استخراج الوقت فقط (الساعة)
                        // الـ API يعيد الوقت بصيغة "2023-10-25 15:00:00"
                        // نحن نريد عرض الساعة فقط "03:00 PM"
                        // سنستخدم DateFormat مخصص لذلك، لكن للسهولة سنستخدم DateTime parsing
                        // (ملاحظة: هذا يتطلب أن يكون weather_model يحتوي على خاصية dt_txt أو نحسبها يدوياً)
                        // *تحديث سريع*: WeatherModel الحالي لا يحفظ الوقت كنص.
                        // *الحل*: سنضيف الوقت الحالي + (index * 3) ساعات لتقريب الوقت، أو نعدل المودل.
                        // الأسهل والأنظف الآن هو استخدام وقت تقريبي للعرض:
                        final time = DateTime.now().add(Duration(hours: (index + 1) * 3));

                        Widget cardContent = Container(
                          width: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('hh:mm a', settings.language).format(time), // الساعة
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                              Lottie.asset(
                                _getWeatherAnimation(hourWeather.mainCondition),
                                height: 30,
                              ),
                              Text(
                                '${hourWeather.temperature.round()}°',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );

                        // تطبيق الزجاج إذا مفعل
                        return settings.enableGlassmorphism
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: cardContent),
                        )
                            : cardContent;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ------------------------------------
                  const Text("توقعات الأيام القادمة", style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // القائمة السفلية
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _forecast?.length ?? 0,
                      itemBuilder: (context, index) {
                        final dayWeather = _forecast![index];

                        Widget cardContent = Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                _getWeatherAnimation(dayWeather.mainCondition),
                                height: 50,
                              ),
                              const SizedBox(height: 5),
                              Text('${dayWeather.temperature.round()}°C',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                DateFormat('E', settings.language).format(DateTime.now().add(Duration(days: index + 1))), // استخدام settings.language
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                        return GestureDetector(
                          onTap: () {
                            // عند الضغط، نفتح النافذة بالتفاصيل
                            // نمرر التاريخ التقريبي لليوم (index + 1)
                            // ونمرر "true" إذا كان الوضع الزجاجي مفعلاً أو الوضع الليلي لتحسين ألوان النصوص
                            bool isGlassMode = settings.enableGlassmorphism || settings.isDarkMode;
                            // 1. حساب تاريخ هذا اليوم (اليوم الحالي + ترتيب العنصر + 1)
                            DateTime date = DateTime.now().add(Duration(days: index + 1));

                            // 2. تمرير التاريخ للدالة
                            _showDailyDetails(context, dayWeather, isGlassMode, date);
                          },
                          child: settings.enableGlassmorphism
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: cardContent,
                            ),
                          )
                              : cardContent,
                        );
                        if (settings.enableGlassmorphism) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: cardContent,
                            ),
                          );
                        } else {
                          return cardContent;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}