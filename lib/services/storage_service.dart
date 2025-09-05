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

  Future<void> removeScanResult(ScanResult result) async {
    final results = await loadScanResults();
    results.removeWhere((r) => r.barcode == result.barcode && r.timestamp == result.timestamp);
    await saveScanResults(results);
  }

  Future<void> clearScanResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scanHistoryKey);
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

  // Methods for history (aliased to scan results)
  Future<List<ScanResult>> loadHistory() {
    return loadScanResults();
  }

  Future<void> saveHistory(List<ScanResult> history) {
    return saveScanResults(history);
  }
}
