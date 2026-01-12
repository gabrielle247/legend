import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legend/constants/app_constants.dart';

// =============================================================================
// 1. VIEW MODEL
// =============================================================================
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

// =============================================================================
// 2. SCREEN IMPLEMENTATION
// =============================================================================
class ViewInvoiceScreen extends StatefulWidget {
  final String? invoiceId;

  const ViewInvoiceScreen({super.key, this.invoiceId});

  @override
  State<ViewInvoiceScreen> createState() => _ViewInvoiceScreenState();
}

class _ViewInvoiceScreenState extends State<ViewInvoiceScreen> {
  late ViewInvoiceViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ViewInvoiceViewModel(widget.invoiceId ?? "0000");
    _initLoad();
  }

  void _initLoad() async {
    await _vm.loadInvoice();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      
      // APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            const Text("Invoice Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(_vm.invoiceNumber, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          ],
        ),
        actions: [
          // Edit Action (If draft/admin)
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white),
            tooltip: "Edit Invoice",
            onPressed: () {},
          ),
          // Print Action
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: "Print",
            onPressed: () {},
          ),
        ],
      ),

      // BODY: ZOOMABLE PAPER
      body: Container(
        color: const Color(0xFF121212), // Slightly lighter black for contrast
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(40),
          child: Center(
            child: Hero(
              tag: 'invoice_paper',
              child: _InvoicePaper(vm: _vm),
            ),
          ),
        ),
      ),

      // ACTION BAR: WHATSAPP SHARE
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _vm.shareViaWhatsApp(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp Brand Color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              icon: const Icon(Icons.share, size: 22),
              label: const Text(
                "SHARE VIA WHATSAPP", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. THE "PAPER" WIDGET (A4 Representation)
// =============================================================================
class _InvoicePaper extends StatelessWidget {
  final ViewInvoiceViewModel vm;

  const _InvoicePaper({required this.vm});

  @override
  Widget build(BuildContext context) {
    // A4 Ratio: 1 : 1.414
    // Base Width: 350 -> Height: ~495
    return Container(
      width: 350,
      height: 495,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: -5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo Placeholder
              Container(
                width: 40, 
                height: 40, 
                decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("INVOICE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFF1E293B))),
                  Text("# ${vm.invoiceNumber}", style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // --- INFO GRID ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FROM
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("FROM:", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  SizedBox(height: 2),
                  Text("KWA LEGEND ACADEMY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text("123 Education Lane\nHarare, Zimbabwe", style: TextStyle(fontSize: 8, color: Color(0xFF475569))),
                ],
              ),
              // TO
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("BILL TO:", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text(vm.guardianName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text("Student: ${vm.studentName}", style: const TextStyle(fontSize: 8, color: Color(0xFF475569))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- TABLE HEADER ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text("DESCRIPTION", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                Expanded(flex: 2, child: Text("TOTAL", textAlign: TextAlign.right, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // --- ITEMS ---
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.items.length,
              separatorBuilder: (_, __) => const Divider(height: 12, thickness: 0.5),
              itemBuilder: (ctx, i) {
                final item = vm.items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(item['desc'], style: const TextStyle(fontSize: 9, color: Color(0xFF1E293B)))),
                      Expanded(flex: 1, child: Text("${item['qty']}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF1E293B)))),
                      Expanded(flex: 2, child: Text("\$${(item['price'] * item['qty']).toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                    ],
                  ),
                );
              },
            ),
          ),

          // --- TOTALS ---
          const Divider(thickness: 1.5, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Due Date: ${DateFormat('dd MMM yyyy').format(vm.dueDate)}", style: const TextStyle(fontSize: 8, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text("Status: UNPAID", style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("TOTAL:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(width: 8),
                  Text("\$${vm.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // --- FOOTER ---
          const Center(
            child: Text(
              "Banking Details: Stanbic Bank | Acc: 9140001234 | Branch: Samora Machel",
              style: TextStyle(fontSize: 7, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}