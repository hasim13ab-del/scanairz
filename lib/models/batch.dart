import 'package:scanairz/models/scan_result.dart';

class Batch {
  final String name;
  final DateTime timestamp;
  final List<ScanResult> scans;

  Batch({required this.name, required this.timestamp, required this.scans});

  Map<String, dynamic> toJson() => {
        'name': name,
        'timestamp': timestamp.toIso8601String(),
        'scans': scans.map((scan) => scan.toJson()).toList(),
      };

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
        name: json['name'],
        timestamp: DateTime.parse(json['timestamp']),
        scans: (json['scans'] as List)
            .map((scanJson) => ScanResult.fromJson(scanJson))
            .toList(),
      );
}
