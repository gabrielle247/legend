class AcademicYear {
  final String id;
  final String schoolId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isLocked;
  final DateTime createdAt;

  AcademicYear({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    this.isLocked = false,
    required this.createdAt,
  });

  factory AcademicYear.fromRow(Map<String, dynamic> row) {
    return AcademicYear(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      name: row['name'] as String,
      startDate: DateTime.tryParse(row['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(row['end_date'] ?? '') ?? DateTime.now(),
      isActive: row['is_active'] == 1 || row['is_active'] == true,
      isLocked: row['is_locked'] == 1 || row['is_locked'] == true,
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AcademicYear copyWith({
    String? id,
    String? schoolId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isLocked,
    DateTime? createdAt,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}