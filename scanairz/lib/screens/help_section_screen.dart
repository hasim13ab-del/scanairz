import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpSectionScreen extends StatelessWidget {
  const HelpSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.darkNavy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const ExpansionTile(
            title: Text('How do I scan a barcode?', style: TextStyle(color: Colors.white)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Point your camera at the barcode and ensure it is within the frame. The app will automatically detect and scan the barcode.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How does batch scanning work?', style: TextStyle(color: Colors.white)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Batch scanning allows you to scan multiple items without saving each one individually. All scans will be collected in a batch that you can save or export later.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How do I sync with my PC?', style: TextStyle(color: Colors.white)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Ensure both your phone and PC are on the same network. Open the PC sync screen and follow the instructions to establish a connection.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Contact Support',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.white),
            title: const Text('Email Support', style: TextStyle(color: Colors.white)),
            subtitle: const Text('support@scanairz.com', style: TextStyle(color: Colors.white70)),
            onTap: () {
              // Open email client
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white),
            title: const Text('Visit Website', style: TextStyle(color: Colors.white)),
            subtitle: const Text('www.scanairz.com', style: TextStyle(color: Colors.white70)),
            onTap: () {
              // Open website
            },
          ),
        ],
      ),
    );
  }
}