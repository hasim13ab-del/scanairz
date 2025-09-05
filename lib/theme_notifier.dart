
import 'package:flutter/material.dart';
import 'package:scanairz/themes.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier(this._themeData);

  ThemeData getTheme() => _themeData;

  void setTheme(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == AppThemes.lightTheme) {
      setTheme(AppThemes.darkTheme);
    } else {
      setTheme(AppThemes.lightTheme);
    }
  }
}
