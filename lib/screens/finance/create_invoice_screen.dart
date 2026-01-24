import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legend/data/constants/app_constants.dart';

/// ============================================================================
/// DATA: Returned to caller on Save (NOT a placebo).
/// Whoever pushes this screen can `await` and persist it.
/// ============================================================================
class CreateInvoiceDraft {
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;

  // Party / Context (keep flexible; backend can enforce required keys later)
  final String studentName;
  final String? studentId;
  final String? studentGrade;
  final String? guardianName;

  final List<CreateInvoiceDraftItem> items;

  CreateInvoiceDraft({
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.studentName,
    required this.items,
    this.studentId,
    this.studentGrade,
    this.guardianName,
  });

  double get subtotal => items.fold(0.0, (s, i) => s + i.total);
  double get tax => 0.0;
  double get total => subtotal + tax;
}

class CreateInvoiceDraftItem {
  final String description;
  final int quantity;
  final double unitPrice;

  CreateInvoiceDraftItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

/// ============================================================================
/// VIEWMODEL: Serious, deterministic UI state.
/// ============================================================================
class CreateInvoiceViewModel extends ChangeNotifier {
  final String invoiceNumber;
  DateTime issueDate;
  DateTime dueDate;

  // Controllers (keeps data stable across rebuilds)
  final TextEditingController studentNameCtrl = TextEditingController();
  final TextEditingController studentIdCtrl = TextEditingController();
  final TextEditingController studentGradeCtrl = TextEditingController();
  final TextEditingController guardianNameCtrl = TextEditingController();

  final List<_InvoiceLineItemDraft> _items = [];
  final Map<String, VoidCallback> _itemListeners = {};

  bool _attemptedSubmit = false;

  CreateInvoiceViewModel._({
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
  }) {
    // Default: 2 professional line items but editable (not fake student, not fake totals)
    addItem(description: "Tuition Fee", quantity: 1, unitPrice: 0.0);
    addItem(description: "Levy / Supplementary", quantity: 1, unitPrice: 0.0);

    // Recalc on party edits where needed
    studentNameCtrl.addListener(_softRebuild);
    studentIdCtrl.addListener(_softRebuild);
    studentGradeCtrl.addListener(_softRebuild);
    guardianNameCtrl.addListener(_softRebuild);
  }

  factory CreateInvoiceViewModel.init() {
    final now = DateTime.now();
    final inv = "INV-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}";
    return CreateInvoiceViewModel._(
      invoiceNumber: inv,
      issueDate: DateTime(now.year, now.month, now.day),
      dueDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 14)),
    );
  }

  List<_InvoiceLineItemDraft> get items => List.unmodifiable(_items);
  bool get attemptedSubmit => _attemptedSubmit;

  double get subtotal => _items.fold(0.0, (s, i) => s + i.total);
  double get tax => 0.0;
  double get total => subtotal + tax;

  bool get isTimelineValid => !dueDate.isBefore(issueDate);

  bool get canSave {
    // “Stand on business”: enforce minimum required inputs.
    final hasStudentName = studentNameCtrl.text.trim().isNotEmpty;
    final hasAtLeastOneValidLine = _items.any((i) => i.isValidLine);
    return hasStudentName && hasAtLeastOneValidLine && isTimelineValid;
  }

  void markAttemptedSubmit() {
    _attemptedSubmit = true;
    notifyListeners();
  }

  void setIssueDate(DateTime d) {
    issueDate = DateTime(d.year, d.month, d.day);
    // keep due >= issue
    if (dueDate.isBefore(issueDate)) {
      dueDate = issueDate;
    }
    notifyListeners();
  }

  void setDueDate(DateTime d) {
    dueDate = DateTime(d.year, d.month, d.day);
    notifyListeners();
  }

  void applyQuickDue(int days) {
    dueDate = issueDate.add(Duration(days: days));
    notifyListeners();
  }

  void applyEndOfMonthDue() {
    final lastDay = DateTime(issueDate.year, issueDate.month + 1, 0);
    dueDate = DateTime(lastDay.year, lastDay.month, lastDay.day);
    notifyListeners();
  }

  void addItem({String description = "", int quantity = 1, double unitPrice = 0.0}) {
    final item = _InvoiceLineItemDraft.create(description: description, quantity: quantity, unitPrice: unitPrice);
    _items.add(item);
    _attachItemListeners(item);
    notifyListeners();
  }

  void removeItemById(String id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final item = _items.removeAt(idx);
    _detachItemListeners(item);
    item.dispose();
    notifyListeners();
  }

  CreateInvoiceDraft buildDraftOrThrow() {
    final studentName = studentNameCtrl.text.trim();
    if (studentName.isEmpty) {
      throw StateError("Student name is required.");
    }
    if (!isTimelineValid) {
      throw StateError("Due date cannot be before issue date.");
    }
    final builtItems = _items
        .where((i) => i.isValidLine)
        .map((i) => CreateInvoiceDraftItem(
              description: i.description.trim(),
              quantity: i.quantity,
              unitPrice: i.unitPrice,
            ))
        .toList();

    if (builtItems.isEmpty) {
      throw StateError("At least one valid line item is required.");
    }

    return CreateInvoiceDraft(
      invoiceNumber: invoiceNumber,
      issueDate: issueDate,
      dueDate: dueDate,
      studentName: studentName,
      studentId: studentIdCtrl.text.trim().isEmpty ? null : studentIdCtrl.text.trim(),
      studentGrade: studentGradeCtrl.text.trim().isEmpty ? null : studentGradeCtrl.text.trim(),
      guardianName: guardianNameCtrl.text.trim().isEmpty ? null : guardianNameCtrl.text.trim(),
      items: builtItems,
    );
  }

  void _attachItemListeners(_InvoiceLineItemDraft item) {
    void listener() => notifyListeners();
    _itemListeners[item.id] = listener;

    item.descriptionCtrl.addListener(listener);
    item.qtyCtrl.addListener(listener);
    item.unitPriceCtrl.addListener(listener);
  }

  void _detachItemListeners(_InvoiceLineItemDraft item) {
    final listener = _itemListeners.remove(item.id);
    if (listener == null) return;

    item.descriptionCtrl.removeListener(listener);
    item.qtyCtrl.removeListener(listener);
    item.unitPriceCtrl.removeListener(listener);
  }

  void _softRebuild() => notifyListeners();

  @override
  void dispose() {
    studentNameCtrl.dispose();
    studentIdCtrl.dispose();
    studentGradeCtrl.dispose();
    guardianNameCtrl.dispose();

    for (final i in _items) {
      _detachItemListeners(i);
      i.dispose();
    }
    _items.clear();
    super.dispose();
  }
}

class _InvoiceLineItemDraft {
  final String id;
  final TextEditingController descriptionCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitPriceCtrl;

  _InvoiceLineItemDraft._({
    required this.id,
    required this.descriptionCtrl,
    required this.qtyCtrl,
    required this.unitPriceCtrl,
  });

  static _InvoiceLineItemDraft create({String description = "", int quantity = 1, double unitPrice = 0.0}) {
    final id = "${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}";
    return _InvoiceLineItemDraft._(
      id: id,
      descriptionCtrl: TextEditingController(text: description),
      qtyCtrl: TextEditingController(text: max(1, quantity).toString()),
      unitPriceCtrl: TextEditingController(text: unitPrice.toStringAsFixed(2)),
    );
  }

  String get description => descriptionCtrl.text;
  int get quantity => max(1, int.tryParse(qtyCtrl.text.trim()) ?? 1);
  double get unitPrice => double.tryParse(unitPriceCtrl.text.trim()) ?? 0.0;
  double get total => quantity * unitPrice;

  bool get isValidLine {
    // Business: must have description and non-negative price; qty >= 1
    final d = description.trim();
    if (d.isEmpty) return false;
    if (unitPrice < 0) return false;
    if (quantity < 1) return false;
    return true;
  }

  void dispose() {
    descriptionCtrl.dispose();
    qtyCtrl.dispose();
    unitPriceCtrl.dispose();
  }
}

/// ============================================================================
/// SCREEN
/// ============================================================================
class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> with SingleTickerProviderStateMixin {
  late final CreateInvoiceViewModel _vm;
  TabController? _tabController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _vm = CreateInvoiceViewModel.init();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _attemptSave() {
    _vm.markAttemptedSubmit();

    // Validate form-level inputs
    final validForm = _formKey.currentState?.validate() ?? false;
    if (!validForm) {
      _showError("Fix the highlighted fields before saving.");
      return;
    }

    if (!_vm.isTimelineValid) {
      _showError("Due date cannot be before issue date.");
      return;
    }

    if (!_vm.canSave) {
      _showError("Invoice needs a Student Name and at least one valid line item.");
      return;
    }

    try {
      final draft = _vm.buildDraftOrThrow();
      // Not placebo: return the draft to caller.
      context.pop(draft);
    } catch (e) {
      _showError(e.toString().replaceFirst("StateError: ", ""));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _money(double v) {
    // Don’t hardcode locale assumptions; keep it simple and consistent.
    final f = NumberFormat.currency(symbol: "\$ ", decimalDigits: 2);
    return f.format(v);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isWide = w >= 920; // auto-adapt; not “desktop-specific”
            _tabController ??= TabController(length: 2, vsync: this);

            return Scaffold(
              backgroundColor: AppColors.backgroundBlack,
              appBar: AppBar(
                backgroundColor: AppColors.backgroundBlack,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Invoice Studio", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "DRAFT • ${_vm.invoiceNumber}",
                      style: TextStyle(color: AppColors.textGrey.withAlpha(180), fontSize: 11),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextButton.icon(
                      onPressed: _vm.canSave ? _attemptSave : _attemptSave, // still validates + explains
                      style: TextButton.styleFrom(
                        backgroundColor: _vm.canSave ? AppColors.successGreen : AppColors.surfaceLightGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.save_alt, size: 18),
                      label: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                bottom: isWide
                    ? null
                    : TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primaryBlue,
                        labelColor: AppColors.primaryBlue,
                        unselectedLabelColor: AppColors.textGrey,
                        tabs: const [
                          Tab(text: "EDITOR", icon: Icon(Icons.edit_note)),
                          Tab(text: "PREVIEW", icon: Icon(Icons.remove_red_eye_outlined)),
                        ],
                      ),
              ),
              body: isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildEditor()),
                        VerticalDivider(width: 1, color: AppColors.surfaceLightGrey.withAlpha(30)),
                        SizedBox(
                          width: min(520, w * 0.42),
                          child: _buildPreview(dense: true),
                        ),
                      ],
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEditor(),
                        _buildPreview(),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: "BILL TO",
              icon: Icons.person,
              children: [
                _LabeledField(
                  label: "Student Name",
                  requiredMark: true,
                  child: TextFormField(
                    controller: _vm.studentNameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: _inputDeco(hint: "e.g. Nyasha Gabriel"),
                    validator: (v) {
                      if ((v ?? "").trim().isEmpty) return "Student name is required";
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: "Student ID (Optional)",
                        helper: "Use when linking to the student record.",
                        child: TextFormField(
                          controller: _vm.studentIdCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDeco(hint: "UUID / internal id"),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: "Grade / Class (Optional)",
                        child: TextFormField(
                          controller: _vm.studentGradeCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDeco(hint: "e.g. Form 4-B"),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: "Guardian / Payer (Optional)",
                  child: TextFormField(
                    controller: _vm.guardianNameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDeco(hint: "e.g. Mr. Thomas Wilson"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: "TIMELINE",
              icon: Icons.event,
              accent: AppColors.primaryBlue.withAlpha(18),
              border: AppColors.primaryBlue.withAlpha(60),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateBox(
                        label: "Issue Date",
                        date: _vm.issueDate,
                        color: Colors.white,
                        onPick: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _vm.issueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) _vm.setIssueDate(d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateBox(
                        label: "Due Date",
                        date: _vm.dueDate,
                        color: _vm.isTimelineValid ? Colors.white : Colors.redAccent,
                        onPick: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _vm.dueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) _vm.setDueDate(d);
                        },
                        warning: !_vm.isTimelineValid ? "Due date must be on/after issue date." : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _QuickChip(label: "Net 7", onTap: () => _vm.applyQuickDue(7)),
                    _QuickChip(label: "Net 14", onTap: () => _vm.applyQuickDue(14)),
                    _QuickChip(label: "Net 30", onTap: () => _vm.applyQuickDue(30)),
                    _QuickChip(label: "End of Month", onTap: _vm.applyEndOfMonthDue),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: "LINE ITEMS",
              icon: Icons.receipt_long,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "At least one valid line is required. Empty lines are ignored on Save.",
                        style: TextStyle(color: AppColors.textGrey.withAlpha(180), fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () => _vm.addItem(description: "", quantity: 1, unitPrice: 0.0),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("ADD"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ..._vm.items.map((it) => _LineItemCard(
                      key: ValueKey(it.id),
                      item: it,
                      attemptedSubmit: _vm.attemptedSubmit,
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: AppColors.surfaceDarkGrey,
                            title: const Text("Remove line item?", style: TextStyle(color: Colors.white)),
                            content: const Text(
                              "This will remove the line item from the invoice.",
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text("Remove", style: TextStyle(color: AppColors.errorRed)),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) _vm.removeItemById(it.id);
                      },
                      money: _money,
                    )),

                const SizedBox(height: 16),
                Divider(color: AppColors.surfaceLightGrey.withAlpha(40)),
                const SizedBox(height: 12),

                _TotalsRow(label: "Subtotal", value: _money(_vm.subtotal)),
                _TotalsRow(label: "Tax", value: _money(_vm.tax)),
                const SizedBox(height: 6),
                _TotalsRow(
                  label: "TOTAL",
                  value: _money(_vm.total),
                  bold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview({bool dense = false}) {
    final a4 = 210 / 297; // width/height
    return Container(
      color: Colors.black87,
      child: Center(
        child: InteractiveViewer(
          minScale: dense ? 0.9 : 0.6,
          maxScale: 3.0,
          boundaryMargin: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dense ? 500 : 420,
            ),
            child: AspectRatio(
              aspectRatio: a4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 18)],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _InvoicePaperTemplate(vm: _vm),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(120), fontSize: 13),
      filled: true,
      fillColor: AppColors.backgroundBlack,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(70)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
    );
  }
}

/// ============================================================================
/// UI Pieces
/// ============================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accent;
  final Color? border;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.accent,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent ?? AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? AppColors.surfaceLightGrey.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlueLight, size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final bool requiredMark;
  final String? helper;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
    this.requiredMark = false,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
            if (requiredMark) ...[
              const SizedBox(width: 6),
              const Text("*", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 3),
          Text(helper!, style: TextStyle(color: AppColors.textGrey.withAlpha(150), fontSize: 10)),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime date;
  final Color color;
  final VoidCallback onPick;
  final String? warning;

  const _DateBox({
    required this.label,
    required this.date,
    required this.color,
    required this.onPick,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM dd, yyyy');
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: warning != null ? Colors.redAccent.withAlpha(130) : AppColors.surfaceLightGrey.withAlpha(70),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
            const SizedBox(height: 6),
            Text(df.format(date), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            if (warning != null) ...[
              const SizedBox(height: 6),
              Text(warning!, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: AppColors.surfaceLightGrey.withAlpha(45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _LineItemCard extends StatelessWidget {
  final _InvoiceLineItemDraft item;
  final VoidCallback onDelete;
  final bool attemptedSubmit;
  final String Function(double) money;

  const _LineItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.attemptedSubmit,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final invalid = attemptedSubmit && !item.isValidLine && item.description.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: invalid ? Colors.redAccent.withAlpha(150) : AppColors.surfaceLightGrey.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator, color: AppColors.textGrey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.descriptionCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Description (e.g. Term 1 Tuition)",
                    hintStyle: TextStyle(color: AppColors.textGrey),
                  ),
                  validator: (v) {
                    // Only validate if user attempted submit AND they typed something (avoid screaming at empty templates)
                    if (!attemptedSubmit) return null;
                    final txt = (v ?? "").trim();
                    if (txt.isEmpty) return "Description required (or clear this line)";
                    return null;
                  },
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                tooltip: "Remove line",
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _miniField(
                  label: "Qty",
                  controller: item.qtyCtrl,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  align: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: _miniField(
                  label: "Unit Price",
                  controller: item.unitPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  prefix: "\$ ",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Line Total", style: TextStyle(color: AppColors.textGrey, fontSize: 10)),
                      const SizedBox(height: 6),
                      Text(
                        money(item.total),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (invalid) ...[
            const SizedBox(height: 8),
            const Text(
              "Invalid line: add description + price, or remove the line.",
              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.number,
    List<TextInputFormatter>? inputFormatters,
    TextAlign align = TextAlign.left,
    String? prefix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 10)),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: align,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              prefixText: prefix,
              prefixStyle: const TextStyle(color: AppColors.textGrey),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _TotalsRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final styleLabel = TextStyle(
      color: AppColors.textGrey.withAlpha(bold ? 210 : 170),
      fontSize: bold ? 12 : 11,
      fontWeight: bold ? FontWeight.bold : FontWeight.w600,
      letterSpacing: bold ? 0.8 : 0.4,
    );
    final styleValue = TextStyle(
      color: Colors.white,
      fontSize: bold ? 16 : 12,
      fontWeight: bold ? FontWeight.bold : FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: styleLabel),
          Text(value, style: styleValue),
        ],
      ),
    );
  }
}

/// ============================================================================
/// PREVIEW TEMPLATE: Uses the VM live.
/// ============================================================================
class _InvoicePaperTemplate extends StatelessWidget {
  final CreateInvoiceViewModel vm;
  const _InvoicePaperTemplate({required this.vm});

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF1E293B);
    const textLight = Color(0xFF64748B);

    String money(double v) => NumberFormat.currency(symbol: "\$ ", decimalDigits: 2).format(v);

    final student = vm.studentNameCtrl.text.trim().isEmpty ? "—" : vm.studentNameCtrl.text.trim();
    final grade = vm.studentGradeCtrl.text.trim().isEmpty ? "" : vm.studentGradeCtrl.text.trim();
    final guardian = vm.guardianNameCtrl.text.trim().isEmpty ? "" : vm.guardianNameCtrl.text.trim();

    final df = DateFormat('MMM dd, yyyy');

    // Build printable items: ignore empty lines (serious behavior)
    final printableItems = vm.items
        .where((i) => i.isValidLine)
        .map((i) => (desc: i.description.trim(), qty: i.quantity, total: i.total))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("INVOICE", style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text(vm.invoiceNumber, style: const TextStyle(color: textLight, fontSize: 11)),
            ],
          ),
          const Divider(thickness: 2, color: textDark),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Issued: ${df.format(vm.issueDate)}", style: const TextStyle(color: textLight, fontSize: 10)),
              Text("Due: ${df.format(vm.dueDate)}", style: TextStyle(color: vm.isTimelineValid ? Colors.redAccent : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),

          const SizedBox(height: 14),

          // Party
          const Text("BILLED TO", style: TextStyle(color: textLight, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(student, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
          if (grade.isNotEmpty) Text(grade, style: const TextStyle(color: textDark, fontSize: 10)),
          if (guardian.isNotEmpty) Text("Payer: $guardian", style: const TextStyle(color: textLight, fontSize: 10)),

          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.grey[200],
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text("  DESCRIPTION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("AMOUNT  ", textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // Rows
          if (printableItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                "No valid line items yet.",
                style: TextStyle(color: textLight.withAlpha(220), fontSize: 10, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...printableItems.map(
              (x) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Text("  ${x.desc}", style: const TextStyle(fontSize: 10, color: textDark))),
                    Expanded(flex: 1, child: Text("${x.qty}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: textDark))),
                    Expanded(flex: 2, child: Text("${money(x.total)}  ", textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: textDark))),
                  ],
                ),
              ),
            ),

          const Spacer(),

          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL DUE", style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(money(vm.total), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              "KwaLegend Academy • Fees Department",
              style: TextStyle(color: textLight, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}
