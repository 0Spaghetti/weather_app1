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
    // 1. التأكد من تفعيل خدمة الموقع
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 2. الحصول على الموقع الحالي
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 3. تحويل الإحداثيات إلى اسم مدينة
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    // استخراج اسم المدينة (أو المنطقة إذا لم تتوفر المدينة)
    String? city = placemarks[0].locality;
    return city ?? "Tripoli"; // قيمة افتراضية في حال الفشل
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
}
