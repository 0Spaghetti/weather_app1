import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsProvider with ChangeNotifier {
  // القيم الافتراضية
  bool _isDarkMode = false;
  bool _isCelsius = true;
  bool _enableGlassmorphism = true;
  bool _showSunDetails = true;
  String _language = 'ar'; // 'ar' or 'en'

  // استدعاء القيم لقراءتها
  bool get isDarkMode => _isDarkMode;
  bool get isCelsius => _isCelsius;
  bool get enableGlassmorphism => _enableGlassmorphism;
  bool get showSunDetails => _showSunDetails;
  String get language => _language;

  // تحميل الإعدادات المحفوظة عند فتح التطبيق
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isCelsius = prefs.getBool('isCelsius') ?? true;
    _enableGlassmorphism = prefs.getBool('enableGlass') ?? true;
    _showSunDetails = prefs.getBool('showSun') ?? true;
    _language = prefs.getString('language') ?? 'ar';
    notifyListeners();
  }

  // دوال لتغيير الإعدادات وحفظها
  void toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
    notifyListeners(); // تحديث التطبيق فوراً
  }

  void toggleUnit(bool value) async {
    _isCelsius = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isCelsius', value);
    notifyListeners();
  }

  void toggleGlass(bool value) async {
    _enableGlassmorphism = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('enableGlass', value);
    notifyListeners();
  }

  void toggleSunDetails(bool value) async {
    _showSunDetails = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showSun', value);
    notifyListeners();
  }

  void changeLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('language', lang);
    notifyListeners();
  }
}