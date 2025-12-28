import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var settings = Provider.of<SettingsProvider>(context);
    bool isDark = settings.isDarkMode;
    // التحقق من اللغة الحالية
    bool isArabic = settings.language == 'ar';

    Color bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF6F6F6);
    Color cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        // تغيير العنوان حسب اللغة
        title: Text(isArabic ? "الإعدادات" : "Settings", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- قسم المظهر ---
            _buildSectionHeader(isArabic ? "المظهر والعرض" : "Appearance", isDark),
            _buildSettingsCard(
              cardColor,
              [
                _buildCustomTile(
                  title: isArabic ? "الوضع الداكن" : "Dark Mode",
                  icon: Icons.dark_mode,
                  iconColor: Colors.purple,
                  isSwitch: true,
                  value: settings.isDarkMode,
                  onChanged: (val) => settings.toggleTheme(val),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildCustomTile(
                  title: isArabic ? "واجهة البطاقات" : "Card Layout",
                  subtitle: isArabic ? "تقسيم الشاشة إلى صناديق" : "Group items in boxes",
                  icon: Icons.dashboard_customize, // أيقونة معبرة
                  iconColor: Colors.indigo,
                  isSwitch: true,
                  value: settings.useCardLayout,
                  onChanged: (val) => settings.toggleCardLayout(val),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildCustomTile(
                  title: isArabic ? "خلفية متحركة" : "Dynamic Background",
                  subtitle: isArabic ? "تغيير الخلفية حسب الوقت والطقس" : "Animate background based on time",
                  icon: Icons.movie_filter, // أيقونة معبرة
                  iconColor: Colors.deepPurpleAccent,
                  isSwitch: true,
                  value: settings.isDynamicBackground,
                  onChanged: (val) => settings.toggleDynamicBackground(val),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildCustomTile(
                  title: isArabic ? "تأثير الزجاج" : "Glassmorphism",
                  icon: Icons.blur_on,
                  iconColor: Colors.blue,
                  isSwitch: true,
                  value: settings.enableGlassmorphism,
                  onChanged: (val) => settings.toggleGlass(val),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildCustomTile(
                  title: isArabic ? "لغة التطبيق" : "Language",
                  icon: Icons.language,
                  iconColor: Colors.teal,
                  isSwitch: false,
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: cardColor,
                      value: settings.language,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 'ar', child: Text("العربية")),
                        DropdownMenuItem(value: 'en', child: Text("English")),
                      ],
                      onChanged: (val) {
                        if (val != null) settings.changeLanguage(val);
                      },
                    ),
                  ),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- قسم الوحدات ---
            _buildSectionHeader(isArabic ? "وحدات القياس" : "Units", isDark),
            _buildSettingsCard(
              cardColor,
              [
                _buildCustomTile(
                  title: isArabic ? "درجة مئوية (°C)" : "Celsius (°C)",
                  subtitle: settings.isCelsius
                      ? (isArabic ? "مفعل" : "Enabled")
                      : (isArabic ? "فهرنهايت مفعل" : "Fahrenheit Enabled"),
                  icon: Icons.thermostat,
                  iconColor: Colors.orange,
                  isSwitch: true,
                  value: settings.isCelsius,
                  onChanged: (val) => settings.toggleUnit(val),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- قسم التفاصيل ---
            _buildSectionHeader(isArabic ? "تفاصيل إضافية" : "Extra Details", isDark),
            _buildSettingsCard(
              cardColor,
              [
                _buildCustomTile(
                  title: isArabic ? "عرض الشروق والغروب" : "Sunrise & Sunset",
                  icon: Icons.wb_twilight,
                  iconColor: Colors.amber,
                  isSwitch: true,
                  value: settings.showSunDetails,
                  onChanged: (val) => settings.toggleSunDetails(val),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // إضافة زر "عن التطبيق"
            TextButton.icon(
              onPressed: () => _showAboutDialog(context, isDark, isArabic),
              icon: Icon(Icons.info_outline, color: Colors.grey.shade500),
              label: Text(
                isArabic ? "عن التطبيق" : "About App",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),

            Text(
              "v1.7.0",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // --- دالة نافذة "عن التطبيق" (ميزة إضافية) ---
  void _showAboutDialog(BuildContext context, bool isDark, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(isArabic ? "عن التطبيق" : "About", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_circle, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              isArabic ? "تم تطوير هذا التطبيق كجزء من مشروع مادة (ITMC323)." : "Developed as a university project.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(isArabic ? "تطوير الطالبين: مهند ومحمد" : "Developer: Mohaned & Mohammed", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? "إغلاق" : "Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildCustomTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    String? subtitle,
    bool isSwitch = false,
    bool? value,
    Function(bool)? onChanged,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
          : null,
      trailing: isSwitch
          ? Switch(
        value: value!,
        onChanged: onChanged,
        activeColor: iconColor,
      )
          : trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 60,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
    );
  }
}