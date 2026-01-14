// lib/models/billing_models.dart

/// The Payment: Money In.
class Payment {
  final String id;
  final String schoolId;
  final String studentId;
  final double amount;
  final String method; // Cash, EcoCash
  final String? reference;
  final DateTime receivedAt;

  Payment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.amount,
    required this.method,
    this.reference,
    required this.receivedAt,
  });

  factory Payment.fromRow(Map<String, dynamic> row) {
    return Payment(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      studentId: row['student_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      method: row['method'] as String,
      reference: row['reference_code'] as String?,
      receivedAt: DateTime.parse(row['received_at']),
    );
  }
}
