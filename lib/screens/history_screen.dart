import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: AppTheme.darkNavy,
      ),
      body: const Center(
        child: Text(
          'Scan history will be displayed here',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}