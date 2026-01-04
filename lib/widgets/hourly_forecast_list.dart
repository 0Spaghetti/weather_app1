import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/providers/settings_provider.dart';
import 'package:weather_app/utils/weather_utils.dart';
import 'package:weather_app/widgets/glass_container.dart';

class HourlyForecastList extends StatelessWidget {
  final List<WeatherModel> hourlyForecast;
  final Function(WeatherModel, DateTime) onHourTap;

  const HourlyForecastList({
    super.key,
    required this.hourlyForecast,
    required this.onHourTap,
  });

  // دالة بناء الواجهة، مسؤولة عن عرض قائمة توقعات الطقس الساعية
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.language == 'ar' ? "خلال الساعات ال12 القادمة" : "HOURLY FORECAST",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hourlyForecast.length,
              itemBuilder: (context, index) {
                final hour = hourlyForecast[index];
                final date = DateTime.now().add(Duration(hours: (index + 1) * 3));
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: GestureDetector(
                    onTap: () => onHourTap(hour, date),
                    child: GlassContainer(
                      isGlassEnabled: settings.enableGlassmorphism,
                      child: SizedBox(
                        width: 80,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('ha', settings.language).format(date),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Lottie.asset(
                              WeatherUtils.getWeatherAnimation(hour.mainCondition),
                              height: 40,
                            ),
                            Text(
                              settings.isCelsius
                                  ? '${hour.temperature.round()}°C'
                                  : '${(hour.temperature * 9 / 5 + 32).round()}°F',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
