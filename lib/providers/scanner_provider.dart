import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanairz/services/storage_service.dart';
import '../models/scan_result.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class ScannedCodesNotifier extends StateNotifier<List<ScanResult>> {
  final StorageService _storageService;

  ScannedCodesNotifier(this._storageService) : super([]);

  Future<void> loadScannedCodes() async {
    state = await _storageService.loadScanResults();
  }

  void addScannedCode(ScanResult result) {
    if (!state.any((element) => element.barcode == result.barcode)) {
      state = [...state, result];
      _storageService.saveScanResults(state);
    }
  }
  
  void clearAll() {
    state = [];
    _storageService.saveScanResults(state);
  }
}

final scannedCodesProvider = StateNotifierProvider<ScannedCodesNotifier, List<ScanResult>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ScannedCodesNotifier(storageService)..loadScannedCodes();
});
