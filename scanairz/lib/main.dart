import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_scan_screen.dart';
import 'screens/batch_scan_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pc_sync_screen.dart';
import 'screens/help_section_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: ScanairzApp()));
}

class ScanairzApp extends StatelessWidget {
  const ScanairzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanairz',
      theme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/scan': (context) => const MainScanScreen(),
        '/batch': (context) => const BatchScanScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/sync': (context) => const PcSyncScreen(),
        '/help': (context) => const HelpSectionScreen(),
      },
    );
  }
}