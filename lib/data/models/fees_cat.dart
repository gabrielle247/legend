class FeeCategory {
  final String id;
  final String schoolId;
  final String name;
  final bool isTaxable;
  final DateTime createdAt;

  FeeCategory({
    required this.id,
    required this.schoolId,
    required this.name,
    this.isTaxable = false,
    required this.createdAt,
  });

  factory FeeCategory.fromRow(Map<String, dynamic> row) {
    return FeeCategory(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      name: row['name'] as String,
      isTaxable: row['is_taxable'] == 1 || row['is_taxable'] == true,
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'is_taxable': isTaxable ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}