import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/storage_service.dart';

final scanResultsProvider = StateNotifierProvider<ScanResultsNotifier, List<ScanResult>>((ref) {
  return ScanResultsNotifier();
});

class ScanResultsNotifier extends StateNotifier<List<ScanResult>> {
  final StorageService _storageService = StorageService();

  ScanResultsNotifier() : super([]) {
    _loadScanResults();
  }

  Future<void> _loadScanResults() async {
    try {
      final results = await _storageService.loadScanResults();
      state = results;
    } catch (e) {
      state = [];
    }
  }

  Future<void> _saveScanResults() async {
    try {
      await _storageService.saveScanResults(state);
    } catch (e) {
      // Handle error appropriately
    }
  }

  void addScanResult(ScanResult result) {
    state = [...state, result];
    _saveScanResults();
  }

  void removeScanResult(String id) {
    state = state.where((result) => result.id != id).toList();
    _saveScanResults();
  }

  void updateScanResult(ScanResult updatedResult) {
    state = state.map((result) => result.id == updatedResult.id ? updatedResult : result).toList();
    _saveScanResults();
  }

  void clearAll() {
    state = [];
    _saveScanResults();
  }

  Future<void> reloadFromStorage() async {
    await _loadScanResults();
  }
}