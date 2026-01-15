// lib/models/billing_models.dart

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
