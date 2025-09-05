import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // PC Connection
  static const String _connectionMethodKey = 'connectionMethod';
  static const String _ipAddressKey = 'ipAddress';
  static const String _portKey = 'port';

  // Scanning Preferences
  static const String _continuousScanKey = 'continuousScan';
  static const String _vibrationKey = 'vibration';
  static const String _laserAnimationKey = 'laserAnimation';

  // Storage Options
  static const String _saveHistoryKey = 'saveHistory';
  static const String _autoClearHistoryDaysKey = 'autoClearHistoryDays';

  // Appearance
  static const String _themeKey = 'theme';

  Future<void> saveSettings({
    required String connectionMethod,
    required String ipAddress,
    required String port,
    required bool continuousScan,
    required bool vibration,
    required bool laserAnimation,
    required bool saveHistory,
    required int autoClearHistoryDays,
    required String theme,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_connectionMethodKey, connectionMethod);
    await prefs.setString(_ipAddressKey, ipAddress);
    await prefs.setString(_portKey, port);
    await prefs.setBool(_continuousScanKey, continuousScan);
    await prefs.setBool(_vibrationKey, vibration);
    await prefs.setBool(_laserAnimationKey, laserAnimation);
    await prefs.setBool(_saveHistoryKey, saveHistory);
    await prefs.setInt(_autoClearHistoryDaysKey, autoClearHistoryDays);
    await prefs.setString(_themeKey, theme);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'connectionMethod': prefs.getString(_connectionMethodKey) ?? 'Wi-Fi',
      'ipAddress': prefs.getString(_ipAddressKey) ?? '',
      'port': prefs.getString(_portKey) ?? '',
      'continuousScan': prefs.getBool(_continuousScanKey) ?? false,
      'vibration': prefs.getBool(_vibrationKey) ?? true,
      'laserAnimation': prefs.getBool(_laserAnimationKey) ?? true,
      'saveHistory': prefs.getBool(_saveHistoryKey) ?? true,
      'autoClearHistoryDays': prefs.getInt(_autoClearHistoryDaysKey) ?? 7,
      'theme': prefs.getString(_themeKey) ?? 'System',
    };
  }
}
