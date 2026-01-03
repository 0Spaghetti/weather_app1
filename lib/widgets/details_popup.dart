import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/models/weather_model.dart';
import 'dart:ui';

class CurrentDetailsSheet extends StatelessWidget {
  final WeatherModel weather;
  final bool isGlass;

  const CurrentDetailsSheet({super.key, required this.weather, this.isGlass = false});

  @override
  Widget build(BuildContext context) {
    final isArabic = Intl.getCurrentLocale() == 'ar';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGlass ? Colors.black.withAlpha(153) : Colors.white,
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
                _buildDetailItem(Icons.water_drop, "${weather.humidity}%", isArabic ? "الرطوبة" : "Humidity", isGlass),
                _buildDetailItem(Icons.air, "${weather.windSpeed} km/h", isArabic ? "الرياح" : "Wind", isGlass),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(Icons.wb_sunny, DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(weather.sunrise * 1000)), isArabic ? "الشروق" : "Sunrise", isGlass),
                _buildDetailItem(Icons.nights_stay, DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(weather.sunset * 1000)), isArabic ? "الغروب" : "Sunset", isGlass),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label, bool isDarkInfo) {
    Color color = isDarkInfo ? Colors.white : Colors.black;
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(color: color.withAlpha(179), fontSize: 14)),
      ],
    );
  }
}
