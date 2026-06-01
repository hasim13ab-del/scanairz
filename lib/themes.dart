import 'package:flutter/material.dart';

class AppThemes {
  static const Color navyDark    = Color(0xFF0A0E1A);
  static const Color navyMid     = Color(0xFF1A2744);
  static const Color navyAccent  = Color(0xFF243455);
  static const Color teal        = Color(0xFF00ACC1);
  static const Color tealLight   = Color(0xFF26C6DA);
  static const Color orange      = Color(0xFFF57C00);
  static const Color orangeLight = Color(0xFFFF9800);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: navyMid,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E4FF),
      onPrimaryContainer: navyDark,
      secondary: teal,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2EBF2),
      onSecondaryContainer: navyDark,
      tertiary: orange,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFE0B2),
      onTertiaryContainer: navyDark,
      error: Color(0xFFE53935),
      onError: Colors.white,
      errorContainer: Color(0xFFFFCDD2),
      onErrorContainer: Color(0xFFB71C1C),
      surface: Colors.white,
      onSurface: navyDark,
      surfaceContainerHighest: Color(0xFFF0F4F8),
      outline: Color(0xFFCFD8DC),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navyMid,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    cardTheme: CardTheme(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: teal,
      unselectedItemColor: Color(0xFF90A4AE),
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
      labelStyle: const TextStyle(color: navyMid),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: teal,
      unselectedLabelColor: Color(0xFF90A4AE),
      indicatorColor: teal,
      dividerColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: navyMid,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: teal,
      onPrimary: Colors.black,
      primaryContainer: navyAccent,
      onPrimaryContainer: tealLight,
      secondary: orange,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF7B3F00),
      onSecondaryContainer: orangeLight,
      tertiary: tealLight,
      onTertiary: Colors.black,
      tertiaryContainer: navyAccent,
      onTertiaryContainer: Colors.white,
      error: Color(0xFFEF5350),
      onError: Colors.black,
      errorContainer: Color(0xFFB71C1C),
      onErrorContainer: Color(0xFFFFCDD2),
      surface: navyMid,
      onSurface: Colors.white,
      surfaceContainerHighest: navyAccent,
      outline: Color(0xFF37474F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navyDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    scaffoldBackgroundColor: navyDark,
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: navyMid,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: teal,
      unselectedItemColor: Color(0xFF546E7A),
      backgroundColor: navyMid,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: navyAccent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF37474F)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF37474F)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: teal,
      unselectedLabelColor: Color(0xFF546E7A),
      indicatorColor: teal,
      dividerColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: navyAccent,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
