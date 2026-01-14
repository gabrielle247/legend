import 'dart:convert';

/// Represents developer channel info (The "Red Phone").
/// Maps to table: `legend.dev`
class LegendDevInfo {
  final String id;
  final String schoolId;
  final String section; // e.g., 'CONTACT', 'PATCH_NOTES'
  final String? content;
  final Map<String, dynamic> payload; // Version numbers, feature flags
  final bool isSecret;
  final DateTime createdAt;

  LegendDevInfo({
    required this.id,
    required this.schoolId,
    required this.section,
    this.content,
    this.payload = const {},
    this.isSecret = true,
    required this.createdAt,
  });

  factory LegendDevInfo.fromRow(Map<String, dynamic> row) {
    return LegendDevInfo(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      section: row['section'] as String,
      content: row['content'] as String?,
      payload: _parseJson(row['payload']),
      isSecret: row['is_secret'] == 1 || row['is_secret'] == true,
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _parseJson(dynamic val) {
    if (val == null) return {};
    if (val is Map) return Map<String, dynamic>.from(val);
    if (val is String) {
      try {
        return jsonDecode(val) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    return {};
  }
}