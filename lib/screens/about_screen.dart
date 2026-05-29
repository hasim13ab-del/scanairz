
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Icon(Icons.qr_code_scanner, size: 72),
          SizedBox(height: 16),
          Text(
            'ScanAiRZ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            'ScanAiRZ turns your phone into a barcode scanner for inventory, history tracking, batch exports, and PC sync.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 24),
          ListTile(
            leading: Icon(Icons.storage),
            title: Text('Local history'),
            subtitle: Text('Saved scan history and batches stay on this device.'),
          ),
          ListTile(
            leading: Icon(Icons.file_upload_outlined),
            title: Text('CSV export'),
            subtitle: Text('Share history and batches with spreadsheet-friendly files.'),
          ),
          ListTile(
            leading: Icon(Icons.sync),
            title: Text('PC sync'),
            subtitle: Text('Send scan data to a configured computer over your network.'),
          ),
        ],
      ),
    );
  }
}
