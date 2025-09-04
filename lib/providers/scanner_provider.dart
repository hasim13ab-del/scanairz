import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/services/storage_service.dart';
import '../models/scan_result.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class ScannedCodesNotifier extends StateNotifier<List<ScanResult>> {
  final StorageService _storageService;
  final SettingsService _settingsService;

  ScannedCodesNotifier(this._storageService, this._settingsService) : super([]);

  Future<void> loadScannedCodes() async {
    state = await _storageService.loadScanResults();
    await _autoClearHistory();
  }

  Future<void> _autoClearHistory() async {
    final settings = await _settingsService.loadSettings();
    final saveHistory = settings['saveHistory'] ?? true;
    final autoClearDays = settings['autoClearHistoryDays'] ?? 7;

    if (saveHistory && autoClearDays > 0) {
      final now = DateTime.now();
      final clearDate = now.subtract(Duration(days: autoClearDays));
      final updatedList = state.where((scan) => scan.timestamp.isAfter(clearDate)).toList();
      
      if(updatedList.length < state.length) {
          state = updatedList;
          await _storageService.saveScanResults(state);
      }
    }
  }

  void addScannedCode(ScanResult result) {
    if (!state.any((element) => element.barcode == result.barcode)) {
      state = [...state, result];
      _storageService.saveScanResults(state);
    }
  }

  void removeScannedCode(ScanResult result) {
    state = state.where((element) => element.barcode != result.barcode).toList();
    _storageService.saveScanResults(state);
  }

  void clearAll() {
    state = [];
    _storageService.saveScanResults(state);
  }
}

final scannedCodesProvider =
    StateNotifierProvider<ScannedCodesNotifier, List<ScanResult>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final settingsService = SettingsService();
  return ScannedCodesNotifier(storageService, settingsService)..loadScannedCodes();
});
