import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFFD7E2E7);      // خلفية مزرقة فاتحة
  static const Color dark = Color(0xFF2D515C);    // أزرار ونصوص داكنة
  static const Color pill = Color(0xFF3D6B78);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    primaryColor: dark,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34, fontWeight: FontWeight.w400, color: Color(0xFF57525D),
      ),
      titleMedium: TextStyle(fontSize: 16, color: Color(0xFF6B6B6B)),
      bodyMedium: TextStyle(fontSize: 15, color: Colors.black87),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE7EFF2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: dark.withOpacity(.3), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: dark.withOpacity(.35), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: pill, width: 1.6),
      ),
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: const TextStyle(color: Color(0xFF8D9AA1)),
    ),
  );
}
