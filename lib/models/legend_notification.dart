import 'dart:convert';
import 'package:legend/models/notification_type.dart';

/// Represents a notification or insight from the Legend Engine.
/// Maps to table: `legend.noti`
class LegendNotification {
  final String id;
  final String schoolId;
  final String? userId; // If null, it's a broadcast message
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic> metadata; // For linking to invoices/students
  final DateTime createdAt;

  LegendNotification({
    required this.id,
    required this.schoolId,
    this.userId,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.isRead = false,
    this.metadata = const {},
    required this.createdAt,
  });

  /// Factory to parse from PowerSync/SQLite Row
  factory LegendNotification.fromRow(Map<String, dynamic> row) {
    return LegendNotification(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      userId: row['user_id'] as String?,
      title: row['title'] as String,
      message: row['message'] as String,
      type: _parseType(row['type']),
      // SQLite stores booleans as 0 or 1 usually, but PowerSync might map to bool.
      // We handle both just in case.
      isRead: row['is_read'] == 1 || row['is_read'] == true,
      metadata: _parseJson(row['metadata']),
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to Map for Saving (if generating local notifications)
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_id': schoolId,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.name.toUpperCase(),
      'is_read': isRead ? 1 : 0,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Helper to safely parse the Enum
  static NotificationType _parseType(String? val) {
    switch (val?.toUpperCase()) {
      case 'SUCCESS': return NotificationType.success;
      case 'WARNING': return NotificationType.warning;
      case 'INSIGHT': return NotificationType.insight;
      case 'SYSTEM': return NotificationType.system;
      default: return NotificationType.info;
    }
  }

  /// Helper to safely parse JSONB columns
  static Map<String, dynamic> _parseJson(dynamic val) {
    if (val == null) return {};
    if (val is Map) return Map<String, dynamic>.from(val);
    if (val is String) {
      try {
        return jsonDecode(val) as Map<String, dynamic>;
      } catch (e) {
        // Fallback if parsing fails
        return {}; 
      }
    }
    return {};
  }
}
