import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legend/constants/app_constants.dart';

// -----------------------------------------------------------------------------
// 1. VIEW MODEL (State & Logic)
// -----------------------------------------------------------------------------
class CreateInvoiceViewModel {
  // Metadata
  final String invoiceNumber; // Auto-generated
  DateTime issueDate;
  DateTime dueDate;
  
  // Student Context
  String? studentName;
  String? studentGrade;
  String? guardianName;

  // Financials
  List<InvoiceLineItem> items;
  
  // Getters
  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get tax => 0.0; // Mock 0% tax for schools usually
  double get total => subtotal + tax;

  CreateInvoiceViewModel({
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    this.studentName,
    this.studentGrade,
    this.guardianName,
    required this.items,
  });

  // Factory for "No User Effort" - Defaults
  factory CreateInvoiceViewModel.init() {
    final now = DateTime.now();
    return CreateInvoiceViewModel(
      invoiceNumber: "INV-${now.year}-${(now.month).toString().padLeft(2,'0')}-0042",
      issueDate: now,
      dueDate: now.add(const Duration(days: 14)), // Default 2 weeks
      items: [
        InvoiceLineItem(description: "Term 1 Tuition Fee", quantity: 1, unitPrice: 450.00),
        InvoiceLineItem(description: "Technology Levy", quantity: 1, unitPrice: 50.00),
      ],
    );
  }

  void addItem() {
    items.add(InvoiceLineItem(description: "New Item", quantity: 1, unitPrice: 0.0));
  }

  void removeItem(int index) {
    items.removeAt(index);
  }
}

class InvoiceLineItem {
  String description;
  int quantity;
  double unitPrice;

  InvoiceLineItem({required this.description, required this.quantity, required this.unitPrice});

  double get total => quantity * unitPrice;
}

// -----------------------------------------------------------------------------
// 2. MAIN SCREEN
// -----------------------------------------------------------------------------
class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> with SingleTickerProviderStateMixin {
  late CreateInvoiceViewModel _vm;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _vm = CreateInvoiceViewModel.init();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveInvoice() {
    // TODO: Write to legend.invoices and legend.invoice_items
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invoice Posted & PDF Generated"), backgroundColor: AppColors.successGreen),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      // APP BAR with TABS
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text("Invoice Studio", style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textGrey,
          tabs: const [
            Tab(text: "EDITOR", icon: Icon(Icons.edit_note)),
            Tab(text: "PREVIEW", icon: Icon(Icons.remove_red_eye_outlined)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: AppColors.successGreen),
            onPressed: _saveInvoice,
            tooltip: "Save & Post",
          ),
        ],
      ),
      
      // BODY
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditor(context),
          _buildPreview(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: THE EDITOR (Data Entry)
  // ---------------------------------------------------------------------------
  Widget _buildEditor(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER DETAILS
          _buildSectionHeader("Bill To"),
          _buildSearchField(
            label: "Select Student",
            icon: Icons.person_search,
            value: _vm.studentName,
            onTap: () {
              // TODO: Open Student Selector Modal
              setState(() {
                _vm.studentName = "James Wilson";
                _vm.studentGrade = "Form 4-B";
                _vm.guardianName = "Mr. Thomas Wilson";
              });
            },
          ),
          if (_vm.studentName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryBlue.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text("Billed to ${_vm.guardianName} (Parent)", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),

          // 2. DATES
          _buildSectionHeader("Timeline"),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: "Issue Date",
                  date: _vm.issueDate,
                  onPick: (d) => setState(() => _vm.issueDate = d),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: "Due Date",
                  date: _vm.dueDate,
                  isDue: true,
                  onPick: (d) => setState(() => _vm.dueDate = d),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. LINE ITEMS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader("Line Items"),
              TextButton.icon(
                onPressed: () => setState(() => _vm.addItem()),
                icon: const Icon(Icons.add, size: 16, color: AppColors.primaryBlue),
                label: const Text("Add Item", style: TextStyle(color: AppColors.primaryBlue)),
              )
            ],
          ),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vm.items.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              return _buildLineItemRow(i);
            },
          ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.surfaceLightGrey),
          
          // 4. TOTALS
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Total Amount", style: TextStyle(color: AppColors.textGrey.withAlpha(150))),
                const SizedBox(height: 4),
                Text(
                  "\$${_vm.total.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: THE PREVIEW (Zoomable Paper)
  // ---------------------------------------------------------------------------
  Widget _buildPreview(BuildContext context) {
    return Container(
      color: Colors.black87, // Dark backdrop for the "Paper"
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        boundaryMargin: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            // A4 Aspect Ratio (approx width 350 -> height 495)
            width: 350, 
            height: 495, 
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 20)],
            ),
            child: _InvoicePaperTemplate(vm: _vm),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSearchField({required String label, required IconData icon, required VoidCallback onTap, String? value}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
        ),
        child: Row(
          children: [
            Icon(icon, color: value != null ? Colors.white : AppColors.textGrey),
            const SizedBox(width: 12),
            Text(
              value ?? label,
              style: TextStyle(color: value != null ? Colors.white : AppColors.textGrey, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime date, required Function(DateTime) onPick, bool isDue = false}) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDue ? Colors.redAccent.withAlpha(50) : AppColors.surfaceLightGrey.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: TextStyle(color: isDue ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemRow(int index) {
    final item = _vm.items[index];
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (_) => setState(() => _vm.removeItem(index)),
      direction: DismissDirection.endToStart,
      background: Container(color: AppColors.errorRed, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: TextFormField(
                initialValue: item.description,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Description", hintStyle: TextStyle(color: AppColors.textGrey)),
                onChanged: (v) => item.description = v,
              ),
            ),
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: item.quantity.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Qty"),
                onChanged: (v) => setState(() => item.quantity = int.tryParse(v) ?? 1),
              ),
            ),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: item.unitPrice.toStringAsFixed(2),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
                decoration: const InputDecoration(border: InputBorder.none, prefixText: "\$ ", prefixStyle: TextStyle(color: AppColors.textGrey)),
                onChanged: (v) => setState(() => item.unitPrice = double.tryParse(v) ?? 0.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. THE PAPER TEMPLATE (Pure UI - No Input)
// -----------------------------------------------------------------------------
class _InvoicePaperTemplate extends StatelessWidget {
  final CreateInvoiceViewModel vm;
  const _InvoicePaperTemplate({required this.vm});

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF1E293B);
    const textLight = Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("INVOICE", style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text(vm.invoiceNumber, style: const TextStyle(color: textLight, fontSize: 12)),
            ],
          ),
          const Divider(thickness: 2, color: textDark),
          const SizedBox(height: 16),
          
          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("BILLED TO:", style: TextStyle(color: textLight, fontSize: 8, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(vm.studentName ?? "Walk-in Student", style: const TextStyle(color: textDark, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(vm.studentGrade ?? "", style: const TextStyle(color: textDark, fontSize: 9)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Due: ${DateFormat('MMM dd, yyyy').format(vm.dueDate)}", style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.grey[200],
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text(" DESCRIPTION", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, ))),
                Expanded(flex: 2, child: Text("AMOUNT ",  textAlign: TextAlign.right,style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold,))),
              ],
            ),
          ),
          
          // Table Rows
          ...vm.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text(" ${item.description}", style: const TextStyle(fontSize: 9, color: textDark))),
                Expanded(flex: 1, child: Text("${item.quantity}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: textDark))),
                Expanded(flex: 2, child: Text("\$${item.total.toStringAsFixed(2)} ", textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, color: textDark))),
              ],
            ),
          )),

          const Spacer(),
          
          // Total
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL DUE", style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("\$${vm.total.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.primaryBlue, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          const Center(child: Text("Thank you for choosing KwaLegend Academy", style: TextStyle(color: textLight, fontSize: 8))),
        ],
      ),
    );
  }
}