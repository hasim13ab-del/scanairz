
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          const Text(
            'Welcome to our Help & Guide center. Here you can find resources to help you get the most out of ScanAiRZ.',
            style: TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 20.0),
          _buildSectionTitle('Tutorial Video'),
          const SizedBox(height: 10.0),
          _buildVideoPlayer(context, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'), // Replace with your actual video URL
          const SizedBox(height: 20.0),
          _buildSectionTitle('Frequently Asked Questions'),
          const SizedBox(height: 10.0),
          _buildFAQ(
            'How do I connect to my PC?',
            'You can connect your device to your PC via Wi-Fi, Bluetooth, or USB. Visit the PC Sync screen for more details.',
          ),
          _buildFAQ(
            'How do I start a batch scan?',
            'From the main screen, tap on the \'Batch Scan\' option. You can then start scanning multiple items, and they will be added to a list.',
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

  Widget _buildVideoPlayer(BuildContext context, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch video')),
            );
          }
        }
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8.0),
            image: const DecorationImage(
              image: NetworkImage('https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg'), // Fetches the video thumbnail
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 60.0,
            ),
          ),
        ),
      ),
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
