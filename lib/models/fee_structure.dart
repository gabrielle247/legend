// lib/models/billing_models.dart

/// The Rules: Defines a fee (e.g., "Form 1 Tuition").
class FeeStructure {
  final String id;
  final String schoolId;
  final String name;
  final double amount;
  final String billingType; // 'tuition', 'transport'
  final String recurrence; // 'termly', 'monthly'
  
  FeeStructure({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.amount,
    required this.billingType,
    required this.recurrence,
  });

  factory FeeStructure.fromRow(Map<String, dynamic> row) {
    return FeeStructure(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      name: row['name'] as String,
      amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
      billingType: row['billing_type'] ?? 'tuition',
      recurrence: row['recurrence'] ?? 'termly',
    );
  }
}
