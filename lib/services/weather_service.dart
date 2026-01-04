import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

// كلاس النتائج المجمعة
class ForecastResult {
  final List<WeatherModel> hourly;
  final List<WeatherModel> daily;

  ForecastResult({required this.hourly, required this.daily});
}

class WeatherService {
  static const String apiKey = 'd0b5d0b5df6911813e6e6e7341bb3065';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // ===================== 1. البحث باسم المدينة =====================

  Future<WeatherModel> getWeather(String cityName, {String lang = 'ar'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather?q=$cityName&appid=$apiKey&units=metric&lang=$lang'),
    );
    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('فشل تحميل الطقس');
    }
  }

  Future<ForecastResult> getComprehensiveForecast(String cityName, {String lang = 'ar'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forecast?q=$cityName&appid=$apiKey&units=metric&lang=$lang'),
    );
    return _processForecastResponse(response);
  }

  // ===================== 2. البحث بالإحداثيات (المفقود) =====================

  Future<WeatherModel> getWeatherByCoordinates(double lat, double lon, {String lang = 'ar'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=$lang'),
    );
    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('فشل تحميل الطقس بالإحداثيات');
    }
  }

  Future<ForecastResult> getComprehensiveForecastByCoordinates(double lat, double lon, {String lang = 'ar'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=$lang'),
    );
    return _processForecastResponse(response);
  }

  // ===================== دالة مساعدة للمعالجة =====================

  ForecastResult _processForecastResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['list'];

      // 1. الساعات: نأخذ أول 8 عناصر
      final hourlyList = list.take(8).map((e) => WeatherModel.fromForecastJson(e)).toList();

      // 2. الأيام: نأخذ قراءات الساعة 12 ظهراً
      final dailyList = list
          .where((e) => e['dt_txt'].contains('12:00:00'))
          .map((e) => WeatherModel.fromForecastJson(e))
          .toList();

      return ForecastResult(hourly: hourlyList, daily: dailyList);
    } else {
      throw Exception('فشل تحميل التوقعات');
    }
  }

  // ===================== 3. الموقع الحالي =====================

  Future<String> getCurrentCity() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return "Tripoli";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return "Tripoli";
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      return placemarks.first.locality ?? "Tripoli";
    } catch (_) {
      return "Tripoli";
    }
  }
}