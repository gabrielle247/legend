// lib/models/billing_models.dart

import 'package:legend/data/models/invoice_status.dart';

/// The Bill: A request for payment.
class Invoice {
  final String id;
  final String schoolId;
  final String studentId;
  final String invoiceNumber;
  final DateTime dueDate;
  final InvoiceStatus status;
  final String? snapshotGrade; // Grade at time of billing
  final double totalAmount; // Calculated often, but useful if stored

  Invoice({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.invoiceNumber,
    required this.dueDate,
    this.status = InvoiceStatus.draft,
    this.snapshotGrade,
    this.totalAmount = 0.0,
  });

  factory Invoice.fromRow(Map<String, dynamic> row) {
    return Invoice(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      studentId: row['student_id'] as String,
      invoiceNumber: row['invoice_number'] as String,
      dueDate: DateTime.parse(row['due_date']),
      status: _parseStatus(row['status']),
      snapshotGrade: row['snapshot_grade'] as String?,
      // Assuming a join or total column exists, else 0
      totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0, 
    );
  }

  static InvoiceStatus _parseStatus(String? val) {
    switch (val?.toUpperCase()) {
      case 'POSTED': return InvoiceStatus.posted;
      case 'PAID': return InvoiceStatus.paid;
      case 'VOID': return InvoiceStatus.voided;
      default: return InvoiceStatus.draft;
    }
  }
}
