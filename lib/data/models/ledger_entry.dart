// lib/models/billing_models.dart

import 'package:legend/data/models/ledger_type.dart';

/// The Truth: Immutable History.
class LedgerEntry {
  final String id;
  final String schoolId;
  final String studentId;
  final LedgerType type; // DEBIT (Owed) vs CREDIT (Paid)
  final double amount;
  final String description;
  final DateTime date;

  LedgerEntry({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory LedgerEntry.fromRow(Map<String, dynamic> row) {
    return LedgerEntry(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      studentId: row['student_id'] as String,
      type: (row['type'] == 'DEBIT') ? LedgerType.debit : LedgerType.credit,
      amount: (row['amount'] as num).toDouble(),
      description: row['description'] ?? 'Transaction',
      date: DateTime.parse(row['occurred_at']),
    );
  }
}