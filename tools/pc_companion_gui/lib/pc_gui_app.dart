import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'pc_gui_state.dart';

void main() {
  runApp(const PcGuiApp());
}

class PcGuiApp extends StatelessWidget {
  const PcGuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanAiRZ PC Companion',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (context) => PcGuiState(),
        child: const PcGuiScreen(),
      ),
    );
  }
}