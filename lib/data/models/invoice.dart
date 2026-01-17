// lib/data/models/invoice.dart
import 'package:legend/data/models/invoice_status.dart';

class Invoice {
  final String id;
  final String schoolId;
  final String studentId;
  final String invoiceNumber;

  // ✅ DB columns you already have
  final String? termId;
  final DateTime dueDate;
  final InvoiceStatus status;
  final String? snapshotGrade;
  final double totalAmount;
  final double paidAmount;
  final String? title;
  final DateTime? createdAt;

  Invoice({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.invoiceNumber,
    this.termId,
    required this.dueDate,
    this.status = InvoiceStatus.draft,
    this.snapshotGrade,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.title,
    this.createdAt,
  });

  factory Invoice.fromRow(Map<String, dynamic> row) {
    return Invoice(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      studentId: row['student_id'] as String,
      invoiceNumber: row['invoice_number'] as String,
      termId: row['term_id'] as String?,
      dueDate: _parseDate(row['due_date']),
      status: _parseStatus(row['status'] as String?),
      snapshotGrade: row['snapshot_grade'] as String?,
      totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (row['paid_amount'] as num?)?.toDouble() ?? 0.0,
      title: row['title'] as String?,
createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,

    );
  }

  static DateTime _parseDate(dynamic raw, {DateTime? fallback}) {
  if (raw == null) return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is String) return DateTime.parse(raw);
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}


  static InvoiceStatus _parseStatus(String? val) {
    final v = val?.trim().toUpperCase();
    switch (v) {
      case 'PENDING':
        return InvoiceStatus.pending;
      case 'PAID':
        return InvoiceStatus.paid;
      case 'PARTIAL':
        return InvoiceStatus.partial;
      case 'OVERDUE':
        return InvoiceStatus.overdue;

      // Accept both
      case 'VOID':
      case 'VOIDED':
        return InvoiceStatus.voided;

      // Accept both spellings
      case 'CANCELLED':
      case 'CANCELED':
        return InvoiceStatus.cancelled;

      case 'DRAFT':
      default:
        return InvoiceStatus.draft;
    }
  }

  
}
