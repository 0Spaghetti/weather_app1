import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // ⚠️ استبدل النص أدناه بمفتاح الـ API الخاص بك من موقع OpenWeather
  static const String apiKey = 'd0b5d0b5df6911813e6e6e7341bb3065';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherModel> getWeather(String cityName, {String lang = 'ar'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather?q=$cityName&appid=$apiKey&units=metric&lang=$lang'),
    );

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('فشل تحميل بيانات الطقس');
    }
  }

  Future<String> getCurrentCity() async {
    try {
      // 1. التأكد من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // بدلاً من الخطأ، نعود لمدينة افتراضية
        return "Tripoli";
      }

      // 2. التحقق من الأذونات وطلبها
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return "Tripoli"; // إذا رفض المستخدم، نعود لمدينة افتراضية
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return "Tripoli"; // إذا رفض نهائياً
      }

      // 3. الحصول على الإحداثيات الحالية
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. تحويل الإحداثيات لاسم مدينة
      // ملاحظة: قد تفشل هذه الخطوة في بعض المحاكيات، لذا وضعناها داخل try/catch
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // التأكد من أن القائمة ليست فارغة قبل أخذ أول عنصر
      if (placemarks.isNotEmpty) {
        String? city = placemarks[0].locality;
        // أحياناً يكون locality فارغاً، نجرب administrativeArea (المنطقة الإدارية)
        return city ?? placemarks[0].administrativeArea ?? "Tripoli";
      } else {
        return "Tripoli";
      }

    } catch (e) {
      print("حدث خطأ في تحديد الموقع: $e");
      return "Tripoli"; // في حال أي خطأ آخر، نعود للمدينة الافتراضية
    }
  }

  // دالة لجلب توقعات 5 أيام
  Future<List<WeatherModel>> getForecast(String cityName, {String lang = 'ar'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forecast?q=$cityName&appid=$apiKey&units=metric&lang=$lang'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['list'];

      // الـ API يعطي طقس كل 3 ساعات. نحن نريد طقساً واحداً لكل يوم (مثلاً الساعة 12 ظهراً)
      // لذلك سنقوم بفلترة القائمة ونأخذ القراءات التي تحتوي على الوقت "12:00:00"
      return list
          .where((item) => item['dt_txt'].contains('12:00:00'))
          .map((item) => WeatherModel.fromJson(item))
          .toList();
    } else {
      throw Exception('فشل تحميل التوقعات');
    }
  }
  // دالة لجلب التوقعات بالساعات (أول 8 قراءات = 24 ساعة)
  Future<List<WeatherModel>> getHourlyForecast(String cityName, {String lang = 'ar'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forecast?q=$cityName&appid=$apiKey&units=metric&lang=$lang'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['list'];

      // نأخذ أول 8 عناصر فقط (8 * 3 ساعات = 24 ساعة)
      return list.take(8).map((item) => WeatherModel.fromJson(item)).toList();
    } else {
      throw Exception('فشل تحميل توقعات الساعات');
    }
  }
}