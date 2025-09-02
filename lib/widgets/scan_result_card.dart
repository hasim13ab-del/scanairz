import 'package:flutter/material.dart';
import 'package:scanairz/models/scan_result.dart';

class ScanResultCard extends StatefulWidget {
  final ScanResult result;
  final Function() onDelete;
  final Function(String) onEdit;

  const ScanResultCard({
    super.key,
    required this.result,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<ScanResultCard> createState() => _ScanResultCardState();
}

class _ScanResultCardState extends State<ScanResultCard> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.result.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _editNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          controller: _notesController,
          decoration: const InputDecoration(hintText: 'Enter notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onEdit(_notesController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          widget.result.barcode,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format: ${widget.result.format}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Time: ${widget.result.timestamp.toString()}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (widget.result.notes != null && widget.result.notes!.isNotEmpty)
              Text(
                'Notes: ${widget.result.notes}',
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: _editNotes,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}