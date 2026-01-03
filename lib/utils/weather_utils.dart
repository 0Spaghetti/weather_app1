import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';

class WeatherUtils {
  static LinearGradient getBackgroundGradient(String? mainCondition) {
    if (mainCondition == null) {
      return const LinearGradient(colors: [Colors.blue, Colors.lightBlue]);
    }
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return LinearGradient(
            colors: [Colors.grey.shade800, Colors.grey.shade500],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return LinearGradient(
            colors: [Colors.grey.shade900, Colors.blueGrey.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case 'thunderstorm':
        return LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.grey.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case 'clear':
        return LinearGradient(
            colors: [Colors.orange.shade400, Colors.blue.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      default:
        return const LinearGradient(
            colors: [Colors.blue, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
    }
  }

  static String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'lib/assets/sunny.json';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'lib/assets/cloudy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'lib/assets/rainy.json';
      case 'thunderstorm':
        return 'lib/assets/thunder.json';
      case 'clear':
        return 'lib/assets/sunny.json';
      default:
        return 'lib/assets/sunny.json';
    }
  }

  static String? getDynamicBackgroundAnimation(WeatherModel? weather) {
    if (weather == null) return null;

    final condition = weather.mainCondition.toLowerCase();
    final now = DateTime.now();
    final sunriseTime = DateTime.fromMillisecondsSinceEpoch(weather.sunrise * 1000);
    final sunsetTime = DateTime.fromMillisecondsSinceEpoch(weather.sunset * 1000);

    bool isNight = now.isAfter(sunsetTime) || now.isBefore(sunriseTime);

    if (condition.contains('clear')) {
      return isNight ? 'lib/assets/clear_night.json' : 'lib/assets/clear_day.json';
    } else if (condition.contains('rain') ||
        condition.contains('drizzle') ||
        condition.contains('thunder')) {
      return isNight
          ? 'lib/assets/rainy_night.json'
          : 'lib/assets/thunder_day.json';
    } else if (condition.contains('cloud')) {
      return isNight ? 'lib/assets/cloudy_night.json' : 'lib/assets/cloudy.json';
    }

    // Default animation if no specific condition is met
    return isNight ? 'lib/assets/clear_night.json' : 'lib/assets/clear_day.json';
  }
}
