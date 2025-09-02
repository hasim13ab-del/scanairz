import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF000080);

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.teal,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.teal,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
