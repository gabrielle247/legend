// lib/models/billing_models.dart

enum InvoiceStatus { draft, posted, paid, voided }
enum LedgerType { debit, credit }

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

/// The Details: Lines inside an invoice.
class InvoiceItem {
  final String id;
  final String schoolId;
  final String invoiceId;
  final String description;
  final double amount;

  InvoiceItem({
    required this.id,
    required this.schoolId,
    required this.invoiceId,
    required this.description,
    required this.amount,
  });

  factory InvoiceItem.fromRow(Map<String, dynamic> row) {
    return InvoiceItem(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      invoiceId: row['invoice_id'] as String,
      description: row['description'] as String,
      amount: (row['amount'] as num).toDouble(),
    );
  }
}

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