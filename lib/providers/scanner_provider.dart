import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';

final scanResultsProvider = StateNotifierProvider<ScanResultsNotifier, List<ScanResult>>((ref) {
  return ScanResultsNotifier();
});

class ScanResultsNotifier extends StateNotifier<List<ScanResult>> {
  ScanResultsNotifier() : super([]);

  void addScanResult(ScanResult result) {
    state = [...state, result];
  }

  void removeScanResult(String id) {
    state = state.where((result) => result.id != id).toList();
  }

  void updateScanResult(ScanResult updatedResult) {
    state = state.map((result) => result.id == updatedResult.id ? updatedResult : result).toList();
  }

  void clearAll() {
    state = [];
  }
}