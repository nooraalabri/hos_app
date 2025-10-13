import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = "en";

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  Locale get locale => Locale(_language);

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void changeLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }
}
