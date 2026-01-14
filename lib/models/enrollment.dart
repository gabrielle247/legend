// lib/models/student_models.dart

class Enrollment {
  final String id;
  final String schoolId;
  final String studentId;
  final String academicYearId;
  final String gradeLevel; // "Form 1"
  final String? classStream; // "East"
  final bool isActive;

  Enrollment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.academicYearId,
    required this.gradeLevel,
    this.classStream,
    this.isActive = true,
  });

  factory Enrollment.fromRow(Map<String, dynamic> row) {
    return Enrollment(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      studentId: row['student_id'] as String,
      academicYearId: row['academic_year_id'] as String,
      gradeLevel: row['grade_level'] as String,
      classStream: row['class_stream'] as String?,
      isActive: row['is_active'] == 1, // SQLite booleans are 0/1
    );
  }
}