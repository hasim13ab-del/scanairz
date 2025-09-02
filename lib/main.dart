import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanairz/features/app_shell.dart';
import 'theme/app_theme.dart';
import 'utils/error_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorHandler.init();
  runApp(const ProviderScope(child: ScanairzApp()));
}

class ScanairzApp extends StatelessWidget {
  const ScanairzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanairz',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
