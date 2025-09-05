
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scanairz/models/batch.dart';
import 'package:scanairz/screens/batch_details_screen.dart';
import 'package:scanairz/services/storage_service.dart';

class BatchesScreen extends StatefulWidget {
  const BatchesScreen({super.key});

  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  final StorageService _storageService = StorageService();
  late Future<List<Batch>> _batchesFuture;

  @override
  void initState() {
    super.initState();
    _batchesFuture = _storageService.loadBatches();
  }

  void _refreshBatches() {
    setState(() {
      _batchesFuture = _storageService.loadBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Batches'),
      ),
      body: FutureBuilder<List<Batch>>(
        future: _batchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('No saved batches yet.'));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final batch = data[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(batch.name),
                    subtitle: Text(
                      '${batch.scans.length} scans on ${DateFormat.yMMMd().format(batch.timestamp)}',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BatchDetailsScreen(batch: batch),
                        ),
                      ).then((_) => _refreshBatches());
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirmation(context, batch),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Something went wrong.'));
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Batch batch) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Batch?'),
          content: Text('Are you sure you want to delete the batch "${batch.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final batches = await _storageService.loadBatches();
                batches.removeWhere((b) => b.name == batch.name);
                await _storageService.saveBatches(batches);
                _refreshBatches();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
