import 'package:legend/models/log_type.dart';

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
}
