import 'package:flutter/material.dart';

class ConnectionStatusBar extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusBar({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: isConnected ? Colors.green : Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}