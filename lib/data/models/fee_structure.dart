import 'dart:convert';

class FeeStructure {
  final String id;
  final String schoolId;
  final String academicYearId;
  final String categoryId;
  final String name;
  final double amount;
  final String billingType; // 'tuition', 'exam', etc.
  final String recurrence; // 'termly', 'monthly'
  final List<int> billableMonths; // [1, 5, 9] for termly starts
  final String? targetGrade; // Specific grade or null for all
  final DateTime createdAt;

  FeeStructure({
    required this.id,
    required this.schoolId,
    required this.academicYearId,
    required this.categoryId,
    required this.name,
    required this.amount,
    this.billingType = 'tuition',
    this.recurrence = 'termly',
    this.billableMonths = const [],
    this.targetGrade,
    required this.createdAt,
  });

  factory FeeStructure.fromRow(Map<String, dynamic> row) {
    return FeeStructure(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      academicYearId: row['academic_year_id'] as String,
      categoryId: row['category_id'] as String,
      name: row['name'] as String,
      amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
      billingType: row['billing_type'] ?? 'tuition',
      recurrence: row['recurrence'] ?? 'termly',
      billableMonths: _parseBillableMonths(row['billable_months']),
      targetGrade: row['target_grade'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_id': schoolId,
      'academic_year_id': academicYearId,
      'category_id': categoryId,
      'name': name,
      'amount': amount,
      'billing_type': billingType,
      'recurrence': recurrence,
      // PowerSync stores arrays/JSON as strings
      'billable_months': jsonEncode(billableMonths),
      'target_grade': targetGrade,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Handle SQLite/PowerSync data vagueness
  static List<int> _parseBillableMonths(dynamic val) {
    if (val == null) return [];
    try {
      if (val is String) {
        // Handle Postgres Array syntax '{1,2,3}' if raw, or JSON '[1,2,3]'
        final cleaned = val.replaceAll('{', '[').replaceAll('}', ']');
        final List<dynamic> list = jsonDecode(cleaned);
        return list.map((e) => e as int).toList();
      }
      if (val is List) return val.map((e) => e as int).toList();
    } catch (e) {
      return [];
    }
    return [];
  }
}