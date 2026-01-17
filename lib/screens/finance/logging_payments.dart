import 'package:legend/app_libs.dart';

import 'package:legend/data/vmodels/logging_payments_view_model.dart';

class LoggingPaymentsScreen extends StatelessWidget {
  final String studentId;

  const LoggingPaymentsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final sid = studentId.trim();
    if (sid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundBlack,
          elevation: 0,
          title: const Text("Error"),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text(
            "Student ID missing. Please go back.",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final financeRepo = context.read<FinanceRepository>();
    final studentRepo = context.read<StudentRepository>();
    final auth = context.read<AuthService>();

    return ChangeNotifierProvider(
      create: (_) => LoggingPaymentsViewModel(financeRepo, studentRepo, auth, sid)..init(),
      child: const _LoggingPaymentsForm(),
    );
  }
}

class _LoggingPaymentsForm extends StatefulWidget {
  const _LoggingPaymentsForm();

  @override
  State<_LoggingPaymentsForm> createState() => _LoggingPaymentsFormState();
}

class _LoggingPaymentsFormState extends State<_LoggingPaymentsForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoggingPaymentsViewModel>();

    final surface = AppColors.surfaceDarkGrey;
    final border = AppColors.surfaceLightGrey.withAlpha(40);

    final standardBoxDecoration = BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border, width: 1),
    );

    final fadedBoxDeco = BoxDecoration(
      color: Colors.blueGrey.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border, width: 1),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
        ),
        title: const Text("Make Payment", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.surfaceLightGrey.withAlpha(40)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorRed.withAlpha(60)),
                ),
                child: Text(
                  vm.error!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.2),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle("Total Cash Received"),
                    const SizedBox(height: 10),

                    // AMOUNT INPUT
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      validator: _validateMoney,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (val) => vm.updateAmount(double.tryParse(val) ?? 0.0),
                      decoration: InputDecoration(
                        hintText: "Enter amount (e.g. 150)",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.grey.shade400, size: 20),
                        filled: true,
                        fillColor: surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryBlue.withAlpha(200)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.errorRed.withAlpha(200)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.errorRed.withAlpha(200)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // QUICK CHIPS
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(vm, "Full Debt", vm.totalOutstandingDebt),
                        _chip(vm, "50%", vm.totalOutstandingDebt / 2),
                        _chip(vm, "\$100", 100),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // SUMMARY
                    Container(
                      decoration: fadedBoxDeco,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _summaryRow(
                            "Total Outstanding Debt:",
                            "\$ ${vm.totalOutstandingDebt.toStringAsFixed(2)}",
                            valueColor: AppColors.errorRed,
                          ),
                          const SizedBox(height: 8),
                          Divider(color: Colors.grey.shade800),
                          const SizedBox(height: 8),
                          _summaryRow(
                            "Amount Entered:",
                            "\$ ${vm.amount.toStringAsFixed(2)}",
                          ),
                          const SizedBox(height: 8),
                          if (vm.remainingCreditAfterDebt > 0)
                            _summaryRow(
                              "Surplus (Future Credit):",
                              "\$ ${vm.remainingCreditAfterDebt.toStringAsFixed(2)}",
                              valueColor: AppColors.successGreen,
                              isBold: true,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // UNPAID LIST
                    _sectionTitle("Bills to be Paid First"),
                    const SizedBox(height: 10),

                    Container(
                      decoration: standardBoxDecoration,
                      child: vm.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : vm.unpaidInvoices.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    "No outstanding bills.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: vm.unpaidInvoices.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: border),
                                  itemBuilder: (context, index) {
                                    final inv = vm.unpaidInvoices[index];
                                    final due = inv.dueDate;
                                    final isNextUp = index == 0;
                                    final outstanding = vm.outstandingOf(inv);

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                      leading: Icon(
                                        Icons.priority_high_rounded,
                                        size: 18,
                                        color: isNextUp ? Colors.orangeAccent : Colors.transparent,
                                      ),
                                      title: Text(
                                        DateFormat('MMMM yyyy').format(DateTime(due.year, due.month)),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: isNextUp ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        vm.getStatusLabel(inv),
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                      ),
                                      trailing: Text(
                                        "\$${outstanding.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          color: isNextUp ? AppColors.errorRed : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),

                    const SizedBox(height: 24),

                    // PAYMENT META
                    _sectionTitle("Payment Details"),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _dropdown(
                            label: "Method",
                            value: vm.method,
                            items: const ["Cash", "EcoCash", "Bank Transfer", "Swipe"],
                            onChanged: (v) => vm.setMethod(v ?? "Cash"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            label: "Reference / Ref No.",
                            controller: _refCtrl,
                            onChanged: vm.setReference,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // FOOTER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: vm.isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              final ok = await vm.logPayment();
                              if (!context.mounted) return;

                              if (ok) {
                                context.pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Payment Logged Successfully")),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(vm.error ?? "Error: Could not process payment.")),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Confirm Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLightGrey.withAlpha(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Widgets / helpers ----

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _chip(LoggingPaymentsViewModel vm, String label, double amount) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.surfaceDarkGrey,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      side: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(40)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        final v = amount.isFinite ? amount : 0.0;
        vm.updateAmount(v);
        _amountCtrl.text = v.toStringAsFixed(2);
      },
    );
  }

  Widget _dropdown({
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
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(40)),
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

  Widget _textField({
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
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(40)),
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

  // STRICT MONEY VALIDATION (0.50 - 500000.00) — adjust limits if you want
  String? _validateMoney(String? v) {
    final raw = (v ?? "").trim();
    if (raw.isEmpty) return "Amount is required.";
    final n = double.tryParse(raw);
    if (n == null) return "Enter a valid number.";
    if (n < 0.50) return "Minimum is \$0.50";
    if (n > 500000) return "Maximum is \$500,000";
    return null;
  }
}
