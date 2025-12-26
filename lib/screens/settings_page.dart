import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات")),
      body: ListView(
        children: [
          // 1. الوضع الليلي
          SwitchListTile(
            title: const Text("الوضع الداكن"),
            secondary: const Icon(Icons.dark_mode),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleTheme(val),
          ),

          // 2. الوحدات
          SwitchListTile(
            title: const Text("درجة مئوية (°C)"),
            subtitle: const Text("أغلق الخيار للتحويل إلى فهرنهايت (°F)"),
            secondary: const Icon(Icons.thermostat),
            value: settings.isCelsius,
            onChanged: (val) => settings.toggleUnit(val),
          ),

          // 3. الزجاج
          SwitchListTile(
            title: const Text("تصميم زجاجي (Glassmorphism)"),
            secondary: const Icon(Icons.blur_on),
            value: settings.enableGlassmorphism,
            onChanged: (val) => settings.toggleGlass(val),
          ),

          // 4. الشروق والغروب
          SwitchListTile(
            title: const Text("عرض الشروق والغروب"),
            secondary: const Icon(Icons.wb_twilight),
            value: settings.showSunDetails,
            onChanged: (val) => settings.toggleSunDetails(val),
          ),

          const Divider(),

          // 5. اللغة
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("لغة التطبيق"),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: const [
                DropdownMenuItem(value: 'ar', child: Text("العربية")),
                DropdownMenuItem(value: 'en', child: Text("English")),
              ],
              onChanged: (val) {
                if (val != null) settings.changeLanguage(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}