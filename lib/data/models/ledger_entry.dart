// lib/data/models/ledger_entry.dart
import 'package:legend/data/models/ledger_type.dart';

class LedgerEntry {
  final String id;
  final String schoolId;
  final String studentId;
  final LedgerType type;

  // ✅ DB columns you already have
  final String category;
  final double amount;
  final String? invoiceId;
  final String? paymentId;

  final String description;
  final DateTime date;

  DateTime get occurredAt => date; // ✅ Backwards compatible alias

  LedgerEntry({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.type,
    required this.category,
    required this.amount,
    this.invoiceId,
    this.paymentId,
    required this.description,
    required this.date,
  });

  factory LedgerEntry.fromRow(Map<String, dynamic> row) {
    return LedgerEntry(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      studentId: row['student_id'] as String,
      type: ((row['type'] as String?)?.toUpperCase() == 'DEBIT')
          ? LedgerType.debit
          : LedgerType.credit,
      category: (row['category'] as String?) ?? 'GENERAL',
      amount: (row['amount'] as num).toDouble(),
      invoiceId: row['invoice_id'] as String?,
      paymentId: row['payment_id'] as String?,
      description: (row['description'] as String?) ?? 'Transaction',
      date: DateTime.parse(row['occurred_at']),
    );
  }
}
