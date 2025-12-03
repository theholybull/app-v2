import 'package:flutter/foundation.dart';

@immutable
class RobotEvent {
  final String type; // e.g. "state", "event", "error"
  final String name; // e.g. "bumper_hit", "battery_low"
  final String? message;
  final String? severity; // e.g. "info", "warn", "error"
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const RobotEvent({
    required this.type,
    required this.name,
    this.message,
    this.severity,
    DateTime? timestamp,
    this.data = const {},
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  factory RobotEvent.fromJson(Map<String, dynamic> json) {
    return RobotEvent(
      type: (json['type'] ?? 'event').toString(),
      name: (json['name'] ?? 'unknown').toString(),
      message: json['message']?.toString(),
      severity: json['severity']?.toString(),
      timestamp: json['timestamp'] is String
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      data: (json['data'] is Map<String, dynamic>)
          ? (json['data'] as Map<String, dynamic>)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'name': name,
      if (message != null) 'message': message,
      if (severity != null) 'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      if (data.isNotEmpty) 'data': data,
    };
  }
}
