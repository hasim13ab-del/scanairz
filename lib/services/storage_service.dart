import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batch.dart';
import '../models/scan_result.dart';

class StorageService {
  static const _scanHistoryKey = 'scanned_codes';
  static const _batchesKey = 'saved_batches';

  // Methods for individual scan results
  Future<void> saveScanResults(List<ScanResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = results.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_scanHistoryKey, encoded);
  }

  Future<List<ScanResult>> loadScanResults() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_scanHistoryKey) ?? [];
    return encoded.map((e) => ScanResult.fromJson(jsonDecode(e))).toList();
  }

  // Methods for batches
  Future<void> saveBatches(List<Batch> batches) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = batches.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_batchesKey, encoded);
  }

  Future<List<Batch>> loadBatches() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_batchesKey) ?? [];
    return encoded.map((e) => Batch.fromJson(jsonDecode(e))).toList();
  }
}
