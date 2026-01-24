class SchoolClass {
  final String id;
  final String schoolId;
  final String gradeId;
  final String name;
  final String? teacherId;
  final DateTime createdAt;

  SchoolClass({
    required this.id,
    required this.schoolId,
    required this.gradeId,
    required this.name,
    this.teacherId,
    required this.createdAt,
  });

  factory SchoolClass.fromRow(Map<String, dynamic> row) {
    return SchoolClass(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      gradeId: row['grade_id'] as String,
      name: row['name'] as String,
      teacherId: row['teacher_id'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_id': schoolId,
      'grade_id': gradeId,
      'name': name,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}