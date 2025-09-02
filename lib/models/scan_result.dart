import 'package:flutter/foundation.dart';

@immutable
class ScanResult {
  final String id;
  final String data;
  final String format;
  final DateTime timestamp;

  const ScanResult({
    required this.id,
    required this.data,
    required this.format,
    required this.timestamp,
  });

  factory ScanResult.fromData(String data, String format) {
    return ScanResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      data: data,
      format: format,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'format': format,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'],
      data: map['data'],
      format: map['format'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ScanResult &&
      other.id == id &&
      other.data == data &&
      other.format == format &&
      other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      data.hashCode ^
      format.hashCode ^
      timestamp.hashCode;
  }
}