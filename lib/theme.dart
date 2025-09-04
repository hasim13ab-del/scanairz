import 'package:flutter/material.dart';

const Color darkNavy = Color(0xFF000080);
const Color scanairzRed = Color(0xFFFF0000);

final appTheme = ThemeData(
  primaryColor: darkNavy,
  colorScheme: const ColorScheme.dark(
    primary: darkNavy,
    secondary: scanairzRed,
    surface: Color(0xFF00004D),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onError: Colors.white,
    error: Colors.redAccent,
  ),
  scaffoldBackgroundColor: const Color(0xFF000033),
  appBarTheme: const AppBarTheme(
    backgroundColor: darkNavy,
    foregroundColor: Colors.white,
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF00004D),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: scanairzRed,
      foregroundColor: Colors.white,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: darkNavy,
    selectedItemColor: scanairzRed,
    unselectedItemColor: Colors.grey,
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white),
  ),
);
