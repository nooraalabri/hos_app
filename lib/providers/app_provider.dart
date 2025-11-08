import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = "en";

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  Locale get locale => Locale(_language);

  AppProvider() {
    _loadSettings(); // ✅ تحميل الإعدادات عند بدء التطبيق
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    _language = prefs.getString('language') ?? 'en';
    notifyListeners(); // 🔔 تحديث الواجهة بعد التحميل
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> changeLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners(); // 🔔 تحديث التطبيق فورًا
  }
}
