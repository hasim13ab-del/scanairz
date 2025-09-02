import 'package:flutter/material.dart';
import '../models/scan_result.dart';

class ScanResultCard extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ScanResultCard({
    super.key,
    required this.result,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xCC0A0E21), // Using hex value for opacity
      child: ListTile(
        title: Text(
          result.data,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Format: ${result.format} - ${result.timestamp.toString()}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}