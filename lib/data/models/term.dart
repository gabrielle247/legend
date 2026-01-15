class Term {
  final String id;
  final String academicYearId;
  final String schoolId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Term({
    required this.id,
    required this.academicYearId,
    required this.schoolId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
  });

  factory Term.fromRow(Map<String, dynamic> row) {
    return Term(
      id: row['id'] as String,
      academicYearId: row['academic_year_id'] as String,
      schoolId: row['school_id'] as String,
      name: row['name'] as String,
      startDate: DateTime.tryParse(row['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(row['end_date'] ?? '') ?? DateTime.now(),
      isActive: row['is_active'] == 1 || row['is_active'] == true,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'academic_year_id': academicYearId,
      'school_id': schoolId,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }
}