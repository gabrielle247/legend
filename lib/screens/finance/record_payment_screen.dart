import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legend/constants/app_constants.dart';

// =============================================================================
// 1. VIEW MODEL
// =============================================================================
class PaymentViewModel {
  // Student Context
  final String? studentId;
  String studentName = "Select Student...";
  String grade = "";
  double currentDebt = 0.0;
  
  // Payment Data
  double amount = 0.0;
  String method = "Cash"; // Cash, EcoCash, Bank
  String reference = "";
  DateTime date = DateTime.now();
  String receiptNumber = "RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

  // Logic State
  bool isLoading = false;

  PaymentViewModel({this.studentId});

  Future<void> loadContext() async {
    isLoading = true;
    await Future.delayed(const Duration(milliseconds: 500)); // Sim network
    
    if (studentId != null) {
      // Mock fetch
      studentName = "Nyasha Gabriel";
      grade = "Form 4A";
      currentDebt = 150.00;
    }
    isLoading = false;
  }

  // Smart Allocation: Suggests what this payment covers
  String get allocationPreview {
    if (amount <= 0) return "Pending input...";
    if (amount >= currentDebt && currentDebt > 0) return "Clears Full Balance";
    return "Partially covers Outstanding Balance";
  }
}

// =============================================================================
// 2. SCREEN IMPLEMENTATION
// =============================================================================
class RecordPaymentScreen extends StatefulWidget {
  final String? studentId;

  const RecordPaymentScreen({super.key, this.studentId});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  late PaymentViewModel _vm;
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = PaymentViewModel(studentId: widget.studentId);
    _initLoad();
  }

  void _initLoad() async {
    await _vm.loadContext();
    if (mounted) setState(() {});
  }

  void _processPayment() {
    if (_vm.amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount"), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    // TODO: Write to legend.payments & legend.ledger
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment of \$${_vm.amount} Recorded!"),
        backgroundColor: AppColors.successGreen,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.successGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text("Receive Payment", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // 1. STUDENT CONTEXT CARD
            // -----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(_vm.studentName[0], style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_vm.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Owes: \$${_vm.currentDebt.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.errorRed, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (_vm.studentId == null)
                    TextButton(
                      onPressed: () {}, // TODO: Search logic
                      child: const Text("Change"),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // -----------------------------------------------------------------
            // 2. THE MONEY INPUT
            // -----------------------------------------------------------------
            Text("AMOUNT RECEIVED", style: TextStyle(color: AppColors.textGrey.withAlpha(150), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            IntrinsicWidth(
              child: TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.successGreen, fontSize: 48, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: "\$ ",
                  prefixStyle: TextStyle(color: AppColors.successGreen, fontSize: 48),
                  border: InputBorder.none,
                  hintText: "0.00",
                  hintStyle: TextStyle(color: Colors.white12),
                ),
                onChanged: (val) {
                  setState(() {
                    _vm.amount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
            ),
            
            // Quick Action Chips
            Wrap(
              spacing: 8,
              children: [
                _buildQuickAmountChip("Full Debt", _vm.currentDebt),
                _buildQuickAmountChip("50%", _vm.currentDebt / 2),
                _buildQuickAmountChip("\$100", 100),
              ],
            ),

            const SizedBox(height: 32),

            // -----------------------------------------------------------------
            // 3. PAYMENT DETAILS
            // -----------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: "Method",
                    value: _vm.method,
                    items: ["Cash", "EcoCash", "Bank Transfer", "Swipe"],
                    onChanged: (val) => setState(() => _vm.method = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: "Reference / Ref No.",
                    onChanged: (val) => _vm.reference = val,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // -----------------------------------------------------------------
            // 4. LIVE RECEIPT PREVIEW
            // -----------------------------------------------------------------
            const Text("RECEIPT PREVIEW", style: TextStyle(color: AppColors.textGrey, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 12),
            _buildThermalReceipt(),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
                shadowColor: AppColors.successGreen.withAlpha(100),
              ),
              icon: const Icon(Icons.print, size: 20),
              label: const Text("CONFIRM & PRINT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET BUILDERS
  // ===========================================================================

  Widget _buildQuickAmountChip(String label, double amount) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.surfaceDarkGrey,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      side: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(30)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        setState(() {
          _vm.amount = amount;
          _amountCtrl.text = amount.toStringAsFixed(2);
        });
      },
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceDarkGrey,
              style: const TextStyle(color: Colors.white),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required ValueChanged<String> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // THE THERMAL RECEIPT VISUAL
  Widget _buildThermalReceipt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD), // Paper White
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.school, color: Colors.black, size: 32),
          const SizedBox(height: 8),
          const Text("KWA LEGEND ACADEMY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
          const Text("OFFICIAL RECEIPT", style: TextStyle(color: Colors.black54, fontSize: 10, letterSpacing: 2)),
          
          const Divider(height: 24, color: Colors.black12, thickness: 1),
          
          _receiptRow("Date", DateFormat("dd/MM/yyyy HH:mm").format(_vm.date)),
          _receiptRow("Receipt #", _vm.receiptNumber),
          _receiptRow("Student", _vm.studentName),
          const SizedBox(height: 8),
          _receiptRow("Method", _vm.method),
          if (_vm.reference.isNotEmpty) _receiptRow("Ref", _vm.reference),
          
          const Divider(height: 24, color: Colors.black12, thickness: 1), // Dashed preferred, logic simplifed
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AMOUNT PAID", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
              Text("\$${_vm.amount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            "Allocation: ${_vm.allocationPreview}",
            style: const TextStyle(color: Colors.black54, fontSize: 10, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          // Barcode Placebo
          Container(height: 30, width: 200, color: Colors.black12, child: const Center(child: Text("||||||| ||| ||||||", style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black26)))),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}