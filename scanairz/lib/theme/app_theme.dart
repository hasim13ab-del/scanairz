import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkNavy = Color(0xFF0A0E21);
  static const Color primaryRed = Color(0xFFE94560);
  static const Color lightGray = Color(0xFF8D8E98);
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: darkNavy,
      scaffoldBackgroundColor: darkNavy,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: white,
        elevation: 0,
      ),
      cardTheme: ThemeData.dark().cardTheme.copyWith(
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xCC0A0E21),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: white),
        bodyMedium: TextStyle(color: lightGray),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}