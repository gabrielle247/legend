import 'dart:convert';

class Enrollment {
  final String id;
  final String schoolId;
  final String studentId;
  final String academicYearId;

  final String gradeLevel; // "Form 1"
  final String? classStream; // "East"
  final bool isActive;

  // Added to match DB columns and existing UI expectations
  final DateTime? createdAt;
  final DateTime? enrollmentDate;

  // Stored as jsonb in Supabase; TEXT(JSON) in SQLite
  final List<String> subjects;
  final double tuitionAmount;

  Enrollment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.academicYearId,
    required this.gradeLevel,
    this.classStream,
    this.isActive = true,
    this.createdAt,
    this.enrollmentDate,
    this.subjects = const [],
    this.tuitionAmount = 0.0,
  });

  // Backward aliases for older code
  DateTime? get enrollment_date => enrollmentDate;

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;

    // Sometimes adapters return int timestamps
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }

    return DateTime.tryParse(raw.toString());
  }

  static List<String> _parseSubjects(dynamic raw) {
    if (raw == null) return const [];

    // Supabase jsonb typically arrives as List<dynamic>
    if (raw is List) return _subjectListFromDynamic(raw);

    // SQLite TEXT containing JSON
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];

    final decoded = _decodeSubjectsString(s);
    if (decoded.isNotEmpty) return decoded;

    // Fallback: CSV/semicolon or single subject string
    final parts = s.split(RegExp(r'[;,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts;

    return const [];
  }

  static List<String> _decodeSubjectsString(String s) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) return _subjectListFromDynamic(decoded);
      if (decoded is String) {
        final nested = jsonDecode(decoded);
        if (nested is List) return _subjectListFromDynamic(nested);
      }
    } catch (_) {}

    return const [];
  }

  static List<String> _subjectListFromDynamic(List<dynamic> items) {
    return items
        .map((e) {
          if (e is Map) {
            final name = e['subjectName'] ?? e['name'];
            return name?.toString();
          }
          return e.toString();
        })
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
  }

  factory Enrollment.fromRow(Map<String, dynamic> row) {
    return Enrollment(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      studentId: row['student_id'] as String,
      academicYearId: row['academic_year_id'] as String,
      gradeLevel: (row['grade_level'] as String?) ?? 'Unknown',
      classStream: row['class_stream'] as String?,
      isActive: row['is_active'] == 1 || row['is_active'] == true,
      createdAt: _parseDate(row['created_at']),
      enrollmentDate: _parseDate(row['enrollment_date']),
      subjects: _parseSubjects(row['subjects']),
      tuitionAmount: (row['tuition_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
