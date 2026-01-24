class PaymentAllocation {
  final String id;
  final String schoolId;
  final String paymentId;
  final String invoiceItemId;
  final double amountAllocated;
  final DateTime createdAt;

  PaymentAllocation({
    required this.id,
    required this.schoolId,
    required this.paymentId,
    required this.invoiceItemId,
    required this.amountAllocated,
    required this.createdAt,
  });

  factory PaymentAllocation.fromRow(Map<String, dynamic> row) {
    return PaymentAllocation(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      paymentId: row['payment_id'] as String,
      invoiceItemId: row['invoice_item_id'] as String,
      amountAllocated: (row['amount_allocated'] as num).toDouble(),
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_id': schoolId,
      'payment_id': paymentId,
      'invoice_item_id': invoiceItemId,
      'amount_allocated': amountAllocated,
      'created_at': createdAt.toIso8601String(),
    };
  }
}