class Grade {
  final String id;
  final String schoolId;
  final String name;
  final int levelIndex; // For sorting (e.g., Form 1 < Form 2)
  final DateTime createdAt;

  Grade({
    required this.id,
    required this.schoolId,
    required this.name,
    this.levelIndex = 0,
    required this.createdAt,
  });

  factory Grade.fromRow(Map<String, dynamic> row) {
    return Grade(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      name: row['name'] as String,
      levelIndex: (row['level_index'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'level_index': levelIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}