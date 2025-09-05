
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/main.dart';
import 'package:scanairz/models/batch.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/remote_config_service.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRemoteConfigService implements RemoteConfigService {
  @override
  bool get showHelpGuide => false;
}

class MockSettingsService implements SettingsService {
  late SharedPreferences _prefs;

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    return {
      'connectionMethod': _prefs.getString('connectionMethod') ?? 'Wi-Fi',
      'ipAddress': _prefs.getString('ipAddress') ?? '',
      'port': _prefs.getString('port') ?? '',
      'continuousScan': _prefs.getBool('continuousScan') ?? false,
      'vibration': _prefs.getBool('vibration') ?? true,
      'laserAnimation': _prefs.getBool('laserAnimation') ?? true,
      'saveHistory': _prefs.getBool('saveHistory') ?? true,
      'autoClearHistoryDays': _prefs.getInt('autoClearHistoryDays') ?? 7,
      'theme': _prefs.getString('theme') ?? 'System',
    };
  }

  @override
  Future<void> saveSettings(
      {required String connectionMethod,
      required String ipAddress,
      required String port,
      required bool continuousScan,
      required bool vibration,
      required bool laserAnimation,
      required bool saveHistory,
      required int autoClearHistoryDays,
      required String theme}) async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString('connectionMethod', connectionMethod);
    await _prefs.setString('ipAddress', ipAddress);
    await _prefs.setString('port', port);
    await _prefs.setBool('continuousScan', continuousScan);
    await _prefs.setBool('vibration', vibration);
    await _prefs.setBool('laserAnimation', laserAnimation);
    await _prefs.setBool('saveHistory', saveHistory);
    await _prefs.setInt('autoClearHistoryDays', autoClearHistoryDays);
    await _prefs.setString('theme', theme);
  }
}

class MockStorageService implements StorageService {
  @override
  Future<List<ScanResult>> loadHistory() => Future.value([]);

  @override
  Future<void> saveHistory(List<ScanResult> history) => Future.value();

  @override
  Future<List<Batch>> loadBatches() => Future.value([]);

  @override
  Future<void> saveBatches(List<Batch> batches) => Future.value();

  @override
  Future<void> clearScanResults() => Future.value();

  @override
  Future<List<ScanResult>> loadScanResults() => Future.value([]);

  @override
  Future<void> removeScanResult(ScanResult result) => Future.value();

  @override
  Future<void> saveScanResults(List<ScanResult> results) => Future.value();
}

class MockPcConnector implements PcConnector {
  @override
  Stream<bool> get connectionStatus => Stream.value(false);

  @override
  bool get isConnected => false;

  @override
  Future<bool> connect(String ipAddress, int port) => Future.value(true);

  @override
  void disconnect() {}

  @override
  Future<void> syncData(List<ScanResult> scans) => Future.value();

  @override
  void dispose() {}
}

void main() {
  testWidgets('Golden test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RemoteConfigService>(
            create: (_) => MockRemoteConfigService(),
          ),
          Provider<SettingsService>(
            create: (_) => MockSettingsService(),
          ),
          Provider<StorageService>(
            create: (_) => MockStorageService(),
          ),
          Provider<PcConnector>(
            create: (_) => MockPcConnector(),
          ),
        ],
        child: const AiRZApp(onboardingComplete: true),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that our counter starts at 0.
    expect(find.text('Scan'), findsOneWidget);
  });
}
