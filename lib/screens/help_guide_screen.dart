
import 'package:flutter/material.dart';
class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Scanning'),
          const SizedBox(height: 10.0),
          _buildFAQ(
            'How do I scan one item?',
            'Open Single Scan, point the camera at a barcode, and keep the code inside the frame until it is detected.',
          ),
          _buildFAQ(
            'How do I scan many items?',
            'Open Batch Scan to collect multiple barcode scans, then save the batch or export it as a CSV file.',
          ),
          const SizedBox(height: 20.0),
          _buildSectionTitle('Frequently Asked Questions'),
          const SizedBox(height: 10.0),
          _buildFAQ(
            'How do I connect to my PC?',
            'You can connect your device to your PC via Wi-Fi, Bluetooth, or USB. Visit the PC Sync screen for more details.',
          ),
          _buildFAQ(
            'Where are my scans stored?',
            'Saved scans are stored on this device. Open History to search, share, export, or clear them.',
          ),
          _buildFAQ(
            'Can I change scan behavior?',
            'Open Settings to turn continuous scan, vibration, laser animation, and history saving on or off.',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(answer),
        ),
      ],
    );
  }
}
