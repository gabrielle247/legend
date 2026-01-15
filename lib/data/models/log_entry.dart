import 'package:legend/data/models/log_type.dart';

class LogEntry {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final LogType type;
  final String performedBy; // "Admin", "System", "Guardian"

  LogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.performedBy,
  });

  // ---------------------------------------------------------------------------
  // FACTORY: DB Row -> Object
  // ---------------------------------------------------------------------------
  factory LogEntry.fromRow(Map<String, dynamic> row) {
    return LogEntry(
      id: row['id'] as String,
      title: row['title'] ?? 'Unknown Activity',
      description: row['description'] ?? '',
      // Safe Date Parsing
      timestamp: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
      // Safe Enum Parsing (Default to System if unknown)
      type: _parseLogType(row['type']),
      performedBy: row['performed_by'] ?? 'System',
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: Enum Parser
  // ---------------------------------------------------------------------------
  static LogType _parseLogType(String? val) {
    if (val == null) return LogType.system;
    
    switch (val.toUpperCase()) {
      case 'FINANCIAL': return LogType.financial;
      case 'ALERT':     return LogType.alert;
      case 'ACADEMIC':  return LogType.academic;
      case 'SYSTEM':    return LogType.system;
      default:          return LogType.system;
    }
  }

  // ---------------------------------------------------------------------------
  // OPTIONAL: Object -> DB Row (For writing logs)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': timestamp.toIso8601String(),
      'type': type.name.toUpperCase(),
      'performed_by': performedBy,
    };
  }
}