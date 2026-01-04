import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/providers/settings_provider.dart';
import 'package:weather_app/utils/weather_utils.dart';
import 'package:weather_app/widgets/glass_container.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherModel weather;
  final VoidCallback onTap;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
    required this.onTap,
  });

  // دالة بناء الواجهة، مسؤولة عن عرض بطاقة الطقس الحالية الرئيسية
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        isGlassEnabled: settings.enableGlassmorphism,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 24),
                const SizedBox(width: 5),
                Text(
                  weather.cityName.toUpperCase(),
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
              WeatherUtils.getWeatherAnimation(weather.mainCondition),
              height: 150,
            ),
            Text(
              settings.isCelsius
                  ? '${weather.temperature.round()}°C'
                  : '${(weather.temperature * 9 / 5 + 32).round()}°F',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 65,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              weather.mainCondition,
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
      ),
    );
  }
}
