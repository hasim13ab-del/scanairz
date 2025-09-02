import 'package:flutter/material.dart';
import 'package:scanairz/features/history/history_screen.dart';
import 'package:scanairz/features/scan/scan_screen.dart';
import 'package:scanairz/features/settings/settings_screen.dart';
import 'package:scanairz/features/shared/widgets/bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ScanScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
