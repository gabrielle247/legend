// lib/data/models/invoice_item.dart
class InvoiceItem {
  final String id;
  final String schoolId;
  final String invoiceId;

  // ✅ DB columns you already have
  final String? feeStructureId;
  final String description;
  final double amount;
  final int quantity;
  final DateTime? createdAt;

  InvoiceItem({
    required this.id,
    required this.schoolId,
    required this.invoiceId,
    this.feeStructureId,
    required this.description,
    required this.amount,
    this.quantity = 1,
    this.createdAt,
  });

  factory InvoiceItem.fromRow(Map<String, dynamic> row) {
    return InvoiceItem(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      invoiceId: row['invoice_id'] as String,
      feeStructureId: row['fee_structure_id'] as String?,
      description: row['description'] as String,
      amount: (row['amount'] as num).toDouble(),
      quantity: (row['quantity'] as num?)?.toInt() ?? 1,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at']) : null,
    );
  }
}
