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
    if (raw is List) return raw.map((e) => e.toString()).toList();

    // SQLite TEXT containing JSON
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];

    try {
      final decoded = jsonDecode(s);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}

    return const [];
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
    );
  }
}
