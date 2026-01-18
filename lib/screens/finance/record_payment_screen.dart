import 'package:flutter/services.dart';
import 'package:legend/app_libs.dart';
import 'package:legend/data/vmodels/payment_view_model.dart';


/// ============================================================================
/// RESULT OBJECT: returned to caller on Confirm.
/// Caller is responsible for persisting (offline-first DB write).
/// ============================================================================
class PaymentDraft {
  final String studentId;
  final String studentName;
  final double amount;
  final String method;
  final String reference;
  final DateTime receivedAt;

  /// Helpful context for UI / receipts
  final double balanceBefore;
  final double balanceAfter;
  final double overpayment;
  final String receiptNumber;

  PaymentDraft({
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.method,
    required this.reference,
    required this.receivedAt,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.overpayment,
    required this.receiptNumber,
  });
}

// =============================================================================
// SCREEN IMPLEMENTATION
// =============================================================================
class RecordPaymentScreen extends StatefulWidget {
  final String? studentId;

  const RecordPaymentScreen({super.key, this.studentId});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  late final PaymentViewModel _vm;

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _refCtrl = TextEditingController();

  bool _attemptedSubmit = false;
  bool _isSubmitting = false;
  bool _isLoadingStudents = false;
  List<Student> _students = [];
  String _studentQuery = "";

@override
void initState() {
  super.initState();

  final financeRepo = context.read<FinanceRepository>();
  final studentRepo = context.read<StudentRepository>();
  final auth = context.read<AuthService>();

  _vm = PaymentViewModel(
    financeRepo,
    studentRepo,
    auth,
    studentId: widget.studentId,
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initLoad(); // <-- use the method so it’s not "unused" AND it triggers setState.
  });
}



  Future<void> _initLoad() async {
    await _vm.init();
    // Ensure a stable default method if VM is empty
    _vm.method = _vm.method.isEmpty ? "Cash" : _vm.method;
    if (mounted) setState(() {});
  }
  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUSINESS CALCS (no placebo)
  // ---------------------------------------------------------------------------
  double get _balanceBefore => max(0.0, _vm.currentDebt);
  double get _amount => max(0.0, _vm.amount);
  double get _balanceAfter => max(0.0, _balanceBefore - _amount);
  double get _overpayment => max(0.0, _amount - _balanceBefore);

  String _money(double v) => NumberFormat.currency(symbol: "\$ ", decimalDigits: 2).format(v);

  String _makeReceiptNumber(DateTime t) {
    // Deterministic enough for offline-first; collision-resistant for a single device.
    final y = t.year.toString();
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final tail = t.millisecondsSinceEpoch.toString().substring(max(0, t.millisecondsSinceEpoch.toString().length - 6));
    return "RCPT-$y$m$d-$tail";
  }

  String _initials(String name) {
    final n = name.trim();
    if (n.isEmpty) return "?";
    final parts = n.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    final a = parts[0].characters.first.toUpperCase();
    final b = parts.length > 1 ? parts[1].characters.first.toUpperCase() : "";
    return "$a$b";
  }

  bool get _studentIsSelected => (_vm.studentId ?? "").trim().isNotEmpty && _vm.studentName.trim().isNotEmpty;

  Future<void> _openStudentPicker() async {
    if (_isLoadingStudents) return;
    if (_students.isEmpty) {
      setState(() => _isLoadingStudents = true);
      try {
        final auth = context.read<AuthService>();
        final school = auth.activeSchool;
        if (school == null) throw Exception("No active school.");
        _students = await context.read<StudentRepository>().getStudents(school.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoadingStudents = false);
      }
    }

    if (!mounted) return;

    _studentQuery = "";

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final q = _studentQuery.toLowerCase().trim();
            final filtered = _students.where((s) {
              if (q.isEmpty) return true;
              return s.firstName.toLowerCase().contains(q) ||
                  s.lastName.toLowerCase().contains(q) ||
                  (s.admissionNumber?.toLowerCase().contains(q) ?? false);
            }).toList();
            final recent = List<Student>.from(_students)
              ..sort((a, b) {
                final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bd.compareTo(ad);
              });

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLightGrey.withAlpha(80),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Select Student",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (val) => setModalState(() => _studentQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search by name or admission...",
                        hintStyle: TextStyle(color: Colors.white.withAlpha(120)),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                        filled: true,
                        fillColor: AppColors.surfaceDarkGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_studentQuery.trim().isEmpty && recent.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Recent",
                          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recent.take(5).map((s) {
                          final name = "${s.firstName} ${s.lastName}".trim();
                          return ActionChip(
                            label: Text(name, overflow: TextOverflow.ellipsis),
                            backgroundColor: AppColors.surfaceDarkGrey,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                            side: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(30)),
                            onPressed: () {
                              setState(() {
                                _vm.studentId = s.id;
                                _vm.student = s;
                                _attemptedSubmit = false;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 360,
                      child: _isLoadingStudents
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                          : filtered.isEmpty
                              ? const Center(
                                  child: Text("No matches found.", style: TextStyle(color: AppColors.textGrey)),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => Divider(
                                    color: AppColors.surfaceLightGrey.withAlpha(30),
                                    height: 1,
                                  ),
                                  itemBuilder: (ctx, index) {
                                    final s = filtered[index];
                                    final name = "${s.firstName} ${s.lastName}".trim();
                                    final adm = (s.admissionNumber ?? "").trim();

                                    return ListTile(
                                      title: Text(name, style: const TextStyle(color: Colors.white)),
                                      subtitle: Text(
                                        adm.isEmpty ? "No admission no." : adm,
                                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _vm.studentId = s.id;
                                          _vm.student = s;
                                          _attemptedSubmit = false;
                                        });
                                        Navigator.pop(ctx);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION: Confirm (returns PaymentDraft)
  // ---------------------------------------------------------------------------
  Future<void> _confirm() async {
    setState(() => _attemptedSubmit = true);

    if (!_studentIsSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select a student first."),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid amount greater than 0."),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final method = _vm.method.trim();
    if (method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select a payment method."),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await _vm.submitPayment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment recorded successfully")),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          final form = SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStudentContextCard(),
                const SizedBox(height: 16),
                _buildBalanceStrip(),
                const SizedBox(height: 28),
                _buildAmountInput(),
                const SizedBox(height: 28),
                _buildPaymentDetails(),
                const SizedBox(height: 22),
                if (!isWide) ...[
                  const Text(
                    "RECEIPT PREVIEW",
                    style: TextStyle(color: AppColors.textGrey, fontSize: 10, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  _buildThermalReceipt(),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          );

          if (!isWide) return form;

          return Row(
            children: [
              Expanded(child: form),
              VerticalDivider(width: 1, color: AppColors.surfaceLightGrey.withAlpha(30)),
              SizedBox(
                width: min(520, constraints.maxWidth * 0.42),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    children: [
                      const Text(
                        "RECEIPT PREVIEW",
                        style: TextStyle(color: AppColors.textGrey, fontSize: 10, letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: SingleChildScrollView(child: _buildThermalReceipt())),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
                shadowColor: AppColors.successGreen.withAlpha(100),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "CONFIRM PAYMENT",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET BUILDERS
  // ===========================================================================

  Widget _buildStudentContextCard() {
    final name = _vm.studentName.trim();
    final owes = _balanceBefore;

    final showChange = widget.studentId == null;

    return Container(
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
            child: Text(_initials(name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? "No student selected" : name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Owes: ${_money(owes)}",
                  style: TextStyle(
                    color: owes > 0 ? AppColors.errorRed : AppColors.successGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_attemptedSubmit && !_studentIsSelected) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Student is required.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          if (showChange)
            TextButton(
              onPressed: _openStudentPicker,
              child: const Text("Change"),
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceStrip() {
    final paid = _amount;
    final after = _balanceAfter;
    final over = _overpayment;

    Widget stat(String label, String value, Color valueColor) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textGrey.withAlpha(160), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat("OWING", _money(_balanceBefore), AppColors.errorRed),
        const SizedBox(width: 10),
        stat("PAID NOW", _money(paid), AppColors.successGreen),
        const SizedBox(width: 10),
        stat("BALANCE", _money(after), after > 0 ? Colors.white : AppColors.successGreen),
        if (over > 0) ...[
          const SizedBox(width: 10),
          stat("OVERPAY", _money(over), Colors.orangeAccent),
        ],
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      children: [
        Text(
          "AMOUNT RECEIVED",
          style: TextStyle(
            color: AppColors.textGrey.withAlpha(150),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicWidth(
          child: TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              LengthLimitingTextInputFormatter(12),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.successGreen, fontSize: 46, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: "\$ ",
              prefixStyle: TextStyle(color: AppColors.successGreen, fontSize: 46),
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickAmountChip("Full Debt", _balanceBefore),
            _buildQuickAmountChip("50%", _balanceBefore / 2),
            _buildQuickAmountChip("\$100", 100),
          ],
        ),
        if (_attemptedSubmit && _amount <= 0) ...[
          const SizedBox(height: 10),
          const Text(
            "Amount must be greater than 0.",
            style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            label: "Method",
            value: _vm.method.isEmpty ? "Cash" : _vm.method,
            items: const ["Cash", "EcoCash", "Bank Transfer", "Swipe"],
            onChanged: (val) => setState(() => _vm.method = (val ?? "Cash")),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            label: "Reference / Ref No.",
            controller: _refCtrl,
            onChanged: (val) => _vm.reference = val,
          ),
        ),
      ],
    );
  }

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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
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
            controller: controller,
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

  // THERMAL RECEIPT PREVIEW (not claiming printed; it previews the draft)
  Widget _buildThermalReceipt() {
    final now = DateTime.now();
    final receiptNo = _makeReceiptNumber(now);

    final name = _vm.studentName.trim().isEmpty ? "—" : _vm.studentName.trim();
    final method = _vm.method.trim().isEmpty ? "Cash" : _vm.method.trim();
    final ref = _vm.reference.trim();

    final allocatedToDebt = min(_amount, _balanceBefore);

    final allocText = _overpayment > 0
        ? "Allocated ${_money(allocatedToDebt)} to debt, ${_money(_overpayment)} as overpayment."
        : "Allocated ${_money(allocatedToDebt)} to outstanding balance.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.school, color: Colors.black, size: 32),
          const SizedBox(height: 8),
          const Text("KWA LEGEND ACADEMY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
          const Text("PAYMENT RECEIPT (DRAFT)", style: TextStyle(color: Colors.black54, fontSize: 10, letterSpacing: 2)),
          const Divider(height: 24, color: Colors.black12, thickness: 1),

          _receiptRow("Date", DateFormat("dd/MM/yyyy HH:mm").format(now)),
          _receiptRow("Receipt #", receiptNo),
          _receiptRow("Student", name),
          _receiptRow("Method", method),
          if (ref.isNotEmpty) _receiptRow("Ref", ref),

          const SizedBox(height: 8),
          _receiptRow("Balance Before", _money(_balanceBefore)),
          _receiptRow("Balance After", _money(_balanceAfter)),
          if (_overpayment > 0) _receiptRow("Overpayment", _money(_overpayment)),

          const Divider(height: 24, color: Colors.black12, thickness: 1),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AMOUNT PAID", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_money(_amount), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            allocText,
            style: const TextStyle(color: Colors.black54, fontSize: 10, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
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
