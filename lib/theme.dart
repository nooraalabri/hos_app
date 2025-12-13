import 'package:flutter/material.dart';

class AppTheme {
  // ألوان الهوية الأساسية (تستخدم في الثيمين)
  static const Color lightBg = Color(0xFFD7E2E7);
  static const Color lightDark = Color(0xFF2D515C);
  static const Color lightPill = Color(0xFF3D6B78);

  static const Color darkBg = Color(0xFF0F1A1E);     // خلفية داكنة ناعمة
  static const Color darkSurface = Color(0xFF1A2A30); // بطاقات داكنة
  static const Color darkText = Colors.white70;
  static const Color darkPrimary = Color(0xFF7DB8C7); // لون رئيسي فاتح جميل للدارك

  // ------------------------------
  //        LIGHT THEME
  // ------------------------------
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      background: lightBg,
      primary: lightDark,
      secondary: lightPill,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34, fontWeight: FontWeight.w400, color: Color(0xFF57525D),
      ),
      titleMedium: TextStyle(fontSize: 16, color: Color(0xFF6B6B6B)),
      bodyMedium: TextStyle(fontSize: 15, color: Colors.black87),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFE7EFF2),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: lightDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: lightPill, width: 1.6),
      ),
      labelStyle: TextStyle(color: Colors.black87),
      hintStyle: TextStyle(color: Color(0xFF8D9AA1)),
    ),
  );

  // ------------------------------
  //        DARK THEME
  // ------------------------------
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      background: darkBg,
      primary: darkPrimary,
      secondary: darkPrimary,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34, fontWeight: FontWeight.w400, color: Colors.white70,
      ),
      titleMedium: TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 15, color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkPrimary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkPrimary, width: 1.6),
      ),
      labelStyle: TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white54),
    ),
  );
}
