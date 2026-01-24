// lib/screens/finance/view_invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/repo/student_repo.dart';
import 'package:legend/data/vmodels/view_invoice_view_model.dart';
import 'package:legend/screens/finance/printing_receipt_screen.dart';

// =============================================================================
// VIEW INVOICE SCREEN (Complete + matches your ViewInvoiceViewModel)
// - Uses Provider to fetch FinanceRepository + StudentRepository
// - Calls vm.load() (not loadInvoice)
// - Reads invoice/items/student from vm fields (no missing getters)
// - No map indexing on InvoiceItem (uses dynamic-safe field access)
// - WhatsApp share routes to receipt preview screen
// =============================================================================
class ViewInvoiceScreen extends StatefulWidget {
  final String? invoiceId;

  const ViewInvoiceScreen({super.key, this.invoiceId});

  @override
  State<ViewInvoiceScreen> createState() => _ViewInvoiceScreenState();
}

class _ViewInvoiceScreenState extends State<ViewInvoiceScreen> {
  ViewInvoiceViewModel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final id = (widget.invoiceId ?? "").trim();
    if (id.isEmpty) {
      // Hard-block: route must provide invoiceId
      setState(() {});
      return;
    }

    final financeRepo = context.read<FinanceRepository>();
    final studentRepo = context.read<StudentRepository>();

    final vm = ViewInvoiceViewModel(financeRepo, studentRepo, id);
    vm.addListener(_onVmChanged);

    setState(() => _vm = vm);

    vm.load();
  }

  void _onVmChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    await _vm?.load();
  }

  void _openReceiptScreen(ViewInvoiceViewModel vm) {
    final invoice = vm.invoice;
    final items = vm.items.map((it) {
      final qty = it.quantity <= 0 ? 1 : it.quantity;
      return {
        'desc': it.description,
        'amount': it.amount * qty,
      };
    }).toList();

    final data = {
      'id': invoice?.invoiceNumber ?? invoice?.id ?? '---',
      'date': (invoice?.createdAt ?? DateTime.now()).toIso8601String(),
      'student': vm.student?.fullName ?? '—',
      'items': items,
      'total': vm.total,
      'cashier': 'System',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrintReceiptScreen(
          data: data,
          type: ReceiptType.invoice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = (widget.invoiceId ?? "").trim();

    // -------------------------------------------------------------------------
    // HARD BLOCKER: Missing invoiceId
    // -------------------------------------------------------------------------
    if (id.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            "Invoice Details",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Missing invoiceId.\nThis screen must be opened with a valid invoice id.",
              style: TextStyle(color: Colors.white70, height: 1.3),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // BEFORE VM BOOTSTRAPS
    // -------------------------------------------------------------------------
    if (_vm == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    final vm = _vm!;

    // -------------------------------------------------------------------------
    // LOADING
    // -------------------------------------------------------------------------
    if (vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    // -------------------------------------------------------------------------
    // ERROR
    // -------------------------------------------------------------------------
    if (vm.error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            "Invoice Details",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vm.error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _retry,
                    child: const Text("Retry"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final invoiceNumber = _invoiceNumber(vm.invoice);
    final heroTag = "invoice_paper_$id";

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
            const Text(
              "Invoice Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              invoiceNumber,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white),
            tooltip: "Edit Invoice",
            onPressed: () {
              _openReceiptScreen(vm);
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: "Print",
            onPressed: () {
              _openReceiptScreen(vm);
            },
          ),
        ],
      ),

      // BODY: ZOOMABLE PAPER
      body: Container(
        color: const Color(0xFF121212),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(40),
          child: Center(
            child: Hero(
              tag: heroTag,
              child: _InvoicePaper(vm: vm),
            ),
          ),
        ),
      ),

      // ACTION BAR (kept but not tied to VM because your VM doesn't implement it)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _openReceiptScreen(vm),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
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

  // ----------------------------------------------------------------------------
  // SAFE HELPERS (no assumptions about missing fields)
  // ----------------------------------------------------------------------------

  String _invoiceNumber(Invoice? invoice) {
    if (invoice == null) return "—";
    final d = invoice as dynamic;
    try {
      final v = d.invoiceNumber;
      if (v != null) return v.toString();
    } catch (_) {}
    try {
      final v = d.id;
      if (v != null) return v.toString();
    } catch (_) {}
    return "—";
  }
}

// =============================================================================
// PAPER WIDGET (A4 Representation)
// Uses VM fields that exist: invoice, items (List<InvoiceItem>), student, total
// =============================================================================
class _InvoicePaper extends StatelessWidget {
  final ViewInvoiceViewModel vm;

  const _InvoicePaper({required this.vm});

  String _money(num v) => "\$${v.toStringAsFixed(2)}";

  DateTime _dueDate(Invoice? invoice) {
    if (invoice == null) return DateTime.now();
    final d = invoice as dynamic;
    try {
      final v = d.dueDate;
      if (v is DateTime) return v;
      if (v != null) return DateTime.tryParse(v.toString()) ?? DateTime.now();
    } catch (_) {}
    return DateTime.now();
  }

  String _statusLabel(Invoice? invoice) {
    if (invoice == null) return "UNKNOWN";
    final d = invoice as dynamic;
    try {
      final v = d.status;
      if (v == null) return "UNKNOWN";
      final s = v.toString().split('.').last.toUpperCase();
      return s;
    } catch (_) {}
    return "UNKNOWN";
  }

  String _studentName(Student? student) {
    return student?.fullName ?? "—";
  }

  String _itemDesc(InvoiceItem it) {
    final d = it as dynamic;
    try {
      final v = d.description;
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    } catch (_) {}
    try {
      final v = d.desc;
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    } catch (_) {}
    try {
      final v = d.title;
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    } catch (_) {}
    return "Item";
  }

  int _itemQty(InvoiceItem it) {
    final d = it as dynamic;
    try {
      final v = d.quantity;
      if (v is int) return v <= 0 ? 1 : v;
      if (v is num) return v.toInt() <= 0 ? 1 : v.toInt();
    } catch (_) {}
    return 1;
  }

  double _itemUnit(InvoiceItem it) {
    final d = it as dynamic;
    try {
      final v = d.amount;
      if (v is num) return v.toDouble();
    } catch (_) {}
    try {
      final v = d.unitPrice;
      if (v is num) return v.toDouble();
    } catch (_) {}
    return 0.0;
  }

  String _invoiceNumber(Invoice? invoice) {
    if (invoice == null) return "—";
    final d = invoice as dynamic;
    try {
      final v = d.invoiceNumber;
      if (v != null) return v.toString();
    } catch (_) {}
    try {
      final v = d.id;
      if (v != null) return v.toString();
    } catch (_) {}
    return "—";
  }

  @override
  Widget build(BuildContext context) {
    final invoice = vm.invoice;
    final due = _dueDate(invoice);
    final status = _statusLabel(invoice);
    final invoiceNumber = _invoiceNumber(invoice);
    final studentName = _studentName(vm.student);

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
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "INVOICE",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "# $invoiceNumber",
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // INFO GRID (no guardianName in your VM, so we show Student)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "FROM:",
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "KWA LEGEND ACADEMY",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    "123 Education Lane\nHarare, Zimbabwe",
                    style: TextStyle(fontSize: 8, color: Color(0xFF475569)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "BILL TO:",
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    studentName,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    "Due: ${DateFormat('dd MMM yyyy').format(due)}",
                    style: const TextStyle(fontSize: 8, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Status: $status",
                    style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // TABLE HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    "DESCRIPTION",
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "QTY",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "TOTAL",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ITEMS
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.items.length,
              separatorBuilder: (_, __) => const Divider(height: 12, thickness: 0.5),
              itemBuilder: (ctx, i) {
                final it = vm.items[i];
                final desc = _itemDesc(it);
                final qty = _itemQty(it);
                final unit = _itemUnit(it);
                final lineTotal = unit * qty;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          desc,
                          style: const TextStyle(fontSize: 9, color: Color(0xFF1E293B)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "$qty",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9, color: Color(0xFF1E293B)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _money(lineTotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // TOTALS
          const Divider(thickness: 1.5, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "TOTAL:",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Text(
                _money(vm.total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // FOOTER
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
