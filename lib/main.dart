import 'package:flutter/material.dart';
import 'screens/weather_page.dart';
import 'package:intl/date_symbol_data_local.dart'; // مهم جداً للتاريخ
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart'; // استيراد البروفايدر
import 'providers/settings_provider.dart'; // استيراد ملف الإعدادات

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar'); // تهيئة اللغة العربية للتاريخ
  runApp(
    // تغليف التطبيق بالبروفايدر
    ChangeNotifierProvider(
      create: (context) => SettingsProvider()..loadSettings(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false, // إخفاء شريط التصحيح المزعج
      title: 'تطبيق الطقس',
      theme: ThemeData.light(useMaterial3: true), // থিম হালকা
      darkTheme: ThemeData.dark(useMaterial3: true), // থিম ডার্ক
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light, // وضع الثيم
      // home: const WeatherPage(), // تحديد صفحة الطقس كصفحة البداية
      home: const SplashScreen(), // <-- ضع هذا السطر الجديد
    );
  }
}
