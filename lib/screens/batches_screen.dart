import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scanairz/models/batch.dart';
import 'package:scanairz/screens/batch_details_screen.dart';
import 'package:scanairz/services/storage_service.dart';

final batchesProvider = FutureProvider<List<Batch>>((ref) async {
  final storageService = StorageService();
  return storageService.loadBatches();
});

class BatchesScreen extends ConsumerWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(batchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Batches'),
      ),
      body: batches.when(
        data: (data) => data.isEmpty
            ? const Center(child: Text('No saved batches yet.'))
            : ListView.builder(
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
                            builder: (context) => BatchDetailsScreen(batch: batch),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmation(context, ref, batch),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Batch batch) {
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
                final storageService = StorageService();
                final batches = await storageService.loadBatches();
                batches.removeWhere((b) => b.name == batch.name);
                await storageService.saveBatches(batches);
                ref.invalidate(batchesProvider);
                if(context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
