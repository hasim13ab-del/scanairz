import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';

class StorageService {
  static const String _scanResultsKey = 'scanResults';
  static const String _settingsKey = 'appSettings';

  Future<void> saveScanResults(List<ScanResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = results.map((result) => result.toMap()).toString();
    await prefs.setString(_scanResultsKey, encodedData);
  }

  Future<List<ScanResult>> loadScanResults() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_scanResultsKey);
    if (data == null) return [];
    
    // Parse the data back to list of ScanResult
    // This is a placeholder; implement proper parsing based on your storage format.
    return [];
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert settings to string and save
    await prefs.setString(_settingsKey, settings.toString());
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_settingsKey);
    if (data == null) return {};
    
    // Parse the data back to settings map
    // This is a placeholder; implement proper parsing
    return {};
  }
}