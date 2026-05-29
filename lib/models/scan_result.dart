import 'dart:convert';

class ScanResult {
  final String id;
  final String barcode;
  final String format;
  final DateTime timestamp;
  final String? notes;

  ScanResult({
    required this.id,
    required this.barcode,
    required this.format,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'format': format,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'],
      barcode: map['barcode'],
      format: map['format'],
      timestamp: DateTime.parse(map['timestamp']),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ScanResult.fromJson(dynamic source) {
    if (source is Map<String, dynamic>) {
      return ScanResult.fromMap(source);
    }
    if (source is Map) {
      return ScanResult.fromMap(Map<String, dynamic>.from(source));
    }
    if (source is String) {
      return ScanResult.fromJson(jsonDecode(source));
    }
    throw ArgumentError('Invalid scan result JSON: $source');
  }

  factory ScanResult.fromData(String barcodeData, String format) {
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      barcode: barcodeData,
      format: format,
      timestamp: DateTime.now(),
    );
  }
}
