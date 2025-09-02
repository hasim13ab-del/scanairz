import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';

class StorageService {
  static const _key = 'scanned_codes';

  Future<void> saveScanResults(List<ScanResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = results.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<List<ScanResult>> loadScanResults() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_key) ?? [];
    return encoded.map((e) => ScanResult.fromJson(jsonDecode(e))).toList();
  }
}
