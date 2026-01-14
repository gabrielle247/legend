import 'package:flutter/material.dart';

class ViewInvoiceViewModel {
  final String invoiceId;
  bool isLoading = true;
  
  // Invoice Data
  late String invoiceNumber;
  late DateTime issueDate;
  late DateTime dueDate;
  late String studentName;
  late String guardianName;
  late String guardianPhone; // For WhatsApp
  late List<Map<String, dynamic>> items;
  late double total;
  late String status; // PAID, UNPAID, OVERDUE

  ViewInvoiceViewModel(this.invoiceId);

  Future<void> loadInvoice() async {
    // Simulate DB Fetch
    await Future.delayed(const Duration(milliseconds: 600));
    
    // MOCK DATA
    invoiceNumber = "INV-2026-001-${invoiceId.substring(0, 4)}";
    issueDate = DateTime.now().subtract(const Duration(days: 2));
    dueDate = DateTime.now().add(const Duration(days: 12));
    studentName = "Nyasha Gabriel";
    guardianName = "Mr. T. Kuudzadombo";
    guardianPhone = "+263771234567";
    status = "UNPAID";
    
    items = [
      {"desc": "Term 1 Tuition", "qty": 1, "price": 450.00},
      {"desc": "Computer Lab Levy", "qty": 1, "price": 50.00},
      {"desc": "Sports Uniform", "qty": 1, "price": 35.00},
    ];
    
    total = items.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));
    isLoading = false;
  }

  Future<void> shareViaWhatsApp(BuildContext context) async {
    // TODO: Implement actual PDF Generation & Share Intent
    // 1. Convert Widget to Image/PDF
    // 2. Write to Temp File
    // 3. ShareX.shareFiles([path], text: "Hello $guardianName, please find invoice...")
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("Generating PDF & Opening WhatsApp..."),
          ],
        ),
        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
