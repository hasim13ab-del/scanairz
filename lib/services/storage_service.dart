import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';

class StorageService {
  static const String _scanResultsKey = 'scanResults';
  static const String _settingsKey = 'appSettings';

  Future<void> saveScanResults(List<ScanResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> resultsJson = results.map((result) => json.encode(result.toMap())).toList();
    await prefs.setStringList(_scanResultsKey, resultsJson);
  }

  Future<List<ScanResult>> loadScanResults() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList(_scanResultsKey);
    if (data == null) return [];
    
    return data.map((item) => ScanResult.fromMap(json.decode(item))).toList();
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_settingsKey);
    if (data == null) return {};
    
    return json.decode(data);
  }
}
