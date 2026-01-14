// lib/models/screen_models.dart

/// Notification / Insight Item.
class InsightItem {
  final String title;
  final String message;
  final String type; // ALERT, INFO
  final DateTime time;

  InsightItem({
    required this.title,
    required this.message,
    required this.type,
    required this.time,
  });
}
