import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/providers/settings_provider.dart';
import 'package:weather_app/utils/weather_utils.dart';
import 'package:weather_app/widgets/glass_container.dart';

class DailyForecastItem extends StatelessWidget {
  final WeatherModel day;
  final int index;
  final VoidCallback onTap;

  const DailyForecastItem({
    super.key,
    required this.day,
    required this.index,
    required this.onTap,
  });

  // دالة بناء الواجهة، مسؤولة عن عرض عنصر واحد من توقعات الأيام القادمة
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final date = DateTime.now().add(Duration(days: index + 1));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          isGlassEnabled: settings.enableGlassmorphism,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE', settings.language).format(date),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Lottie.asset(
                        WeatherUtils.getWeatherAnimation(day.mainCondition),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      settings.isCelsius
                          ? '${day.temperature.round()}°C'
                          : '${(day.temperature * 9 / 5 + 32).round()}°F',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
