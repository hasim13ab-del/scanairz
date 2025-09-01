import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/scan_result.dart';

class StorageService {
  static const String _scanResultsKey = 'scanResults';
  static const String _settingsKey = 'appSettings';

  Future<void> saveScanResults(List<ScanResult> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(results.map((result) => result.toMap()).toList());
      await prefs.setString(_scanResultsKey, encodedData);
    } catch (e) {
      throw Exception('Failed to save scan results: $e');
    }
  }

  Future<List<ScanResult>> loadScanResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_scanResultsKey);
      if (data == null) return [];
      
      final List<dynamic> decodedData = jsonDecode(data);
      return decodedData.map((item) => ScanResult.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load scan results: $e');
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(settings);
      await prefs.setString(_settingsKey, encodedData);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_settingsKey);
      if (data == null) return {};
      
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      throw Exception('Failed to load settings: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scanResultsKey);
      await prefs.remove(_settingsKey);
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}