// lib/screens/students/add_student_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/repo/student_repo.dart';
import 'package:legend/data/services/auth/auth.dart';
import 'package:legend/data/vmodels/add_student_view_model.dart';

class AddStudentScreen extends StatelessWidget {
  const AddStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final repo = context.read<StudentRepository>();

    // If no active school, do NOT create a VM with '' (it produces misleading config errors).
    if (auth.activeSchool == null) {
      return const _NoActiveSchoolScreen();
    }

    return ChangeNotifierProvider<AddStudentViewModel>(
      create: (_) => AddStudentViewModel(repo, auth.activeSchool!.id),
      child: const _AddStudentContent(),
    );
  }
}

class _NoActiveSchoolScreen extends StatelessWidget {
  const _NoActiveSchoolScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: const Text("NEW ADMISSION", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textGrey),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(60)),
          ),
          child: const Text(
            "No active school context was found.\nPlease login again.",
            style: TextStyle(color: Colors.white, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _AddStudentContent extends StatefulWidget {
  const _AddStudentContent();

  @override
  State<_AddStudentContent> createState() => _AddStudentContentState();
}

class _AddStudentContentState extends State<_AddStudentContent> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  Future<void> _handleSubmit(AddStudentViewModel vm) async {
    // 1) Form validators
    if (!_formKey.currentState!.validate()) {
      _showError("Fix the highlighted fields.");
      return;
    }

    // 2) Required: Class + Subjects
    if (vm.selectedGradeName == null || vm.selectedGradeName!.trim().isEmpty) {
      _showError("Assigned Class / Grade is required.");
      return;
    }
    if (vm.selectedSubjects.isEmpty) {
      _showError("Select at least one subject.");
      return;
    }

    // 3) Financial guardrails (critical to prevent silent credit loss)
    final openingDebt = vm.totalDebt;
    final initialPayment = vm.initialPay;
    final tuitionAmount = vm.tuitionAmount;
    final projectedInvoice = vm.generateInvoiceNow ? tuitionAmount : 0.0;

    if (initialPayment > 0 && openingDebt <= 0 && projectedInvoice <= 0) {
      _showError("Initial Payment needs an Opening Balance or a First Invoice. Enable first invoice or keep Initial Payment at 0.");
      return;
    }
    if (initialPayment > openingDebt + projectedInvoice) {
      _showError("Initial Payment cannot exceed Opening Balance plus the First Invoice.");
      return;
    }

    // 4) Submit
    final success = await vm.submit();

    if (!mounted) return;

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Student admitted. Financial profile created."),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError(vm.error ?? "Admission failed.");
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

  Future<void> _pickSubjects(BuildContext context, AddStudentViewModel vm, {required bool desktop}) async {
    if (desktop) {
      final res = await showDialog<List<String>>(
        context: context,
        barrierColor: Colors.black.withAlpha(180),
        builder: (_) => _SubjectsDialog(
          allSubjects: vm.availableSubjects,
          alreadySelected: vm.selectedSubjects,
        ),
      );
      if (res != null) vm.updateSubjects(res);
      return;
    }

    final res = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubjectSelectionModal(
        allSubjects: vm.availableSubjects,
        alreadySelected: vm.selectedSubjects,
      ),
    );

    if (res != null) vm.updateSubjects(res);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddStudentViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    if (vm.blockingError != null) {
      return _buildBlockingError(context, vm.blockingError!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final maxBodyWidth = isWide ? 1200.0 : double.infinity;

        final form = Form(
          key: _formKey,
          child: Column(
            children: [
              _IdentitySection(vm: vm, isWide: isWide),
              const SizedBox(height: 16),
              _AcademicSection(vm: vm, isWide: isWide, onPickSubjects: () => _pickSubjects(context, vm, desktop: isWide)),
              const SizedBox(height: 16),
              _GuardianSection(vm: vm, isWide: isWide),
              const SizedBox(height: 16),
              _FinancialSection(vm: vm, isWide: isWide),
              const SizedBox(height: 18),
              if (!isWide) const SizedBox(height: 64), // space for bottom bar
            ],
          ),
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundBlack,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textGrey),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NEW ADMISSION",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  vm.currentTermLabel,
                  style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: vm.randomizeData,
                tooltip: "Auto-Fill",
                icon: const Icon(Icons.auto_fix_high, color: Colors.purpleAccent, size: 20),
              ),
              const SizedBox(width: 6),
              if (isWide)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8),
                  child: TextButton.icon(
                    onPressed: () => _handleSubmit(vm),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.save_alt, size: 16),
                    label: const Text("COMMIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ],
          ),

          // Mobile: sticky action bar
          bottomNavigationBar: isWide
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDarkGrey,
                      border: Border(top: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(50))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniSummaryLine(vm: vm),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _handleSubmit(vm),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.save_alt, size: 18),
                          label: const Text("Commit", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBodyWidth),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Scrollbar(
                              thumbVisibility: true,
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                primary: false,
                                child: form,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: _AdmissionSummaryPanel(vm: vm),
                          ),
                        ],
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          primary: false,
                          child: form,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockingError(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textGrey),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.errorRed),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.errorRed.withAlpha(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, color: AppColors.errorRed, size: 40),
              const SizedBox(height: 16),
              Text(
                error,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceLightGrey),
                child: const Text("Go Back"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTIONS
// -----------------------------------------------------------------------------
class _IdentitySection extends StatelessWidget {
  final AddStudentViewModel vm;
  final bool isWide;
  const _IdentitySection({required this.vm, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "LEGAL IDENTITY",
      icon: Icons.badge_outlined,
      subtitle: "Required for enrollment + billing identity.",
      children: [
        _Responsive2Col(
          isWide: isWide,
          left: _CompactTextField(
            controller: vm.firstNameCtrl,
            label: "First Name",
            hint: "e.g. Nyasha",
            validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
            textInputAction: TextInputAction.next,
          ),
          right: _CompactTextField(
            controller: vm.lastNameCtrl,
            label: "Last Name",
            hint: "e.g. Gabriel",
            validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 12),
        _Responsive2Col(
          isWide: isWide,
          left: _CompactDropdown(
            value: vm.selectedGender,
            items: const ['Male', 'Female'],
            label: "Gender",
            hint: "Select gender...",
            onChanged: (v) => vm.selectedGender = v,
          ),
          right: _CompactDropdown(
            value: vm.selectedStudentType,
            items: const ['ACADEMY', 'PRIVATE'],
            label: "Student Type",
            hint: "Select type...",
            onChanged: (v) => vm.selectedStudentType = v,
          ),
        ),
      ],
    );
  }
}

class _AcademicSection extends StatelessWidget {
  final AddStudentViewModel vm;
  final bool isWide;
  final VoidCallback onPickSubjects;

  const _AcademicSection({required this.vm, required this.isWide, required this.onPickSubjects});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "ACADEMIC PLACEMENT",
      icon: Icons.school_outlined,
      subtitle: "Class placement and subject enrollment.",
      children: [
        _CompactDropdown(
          value: vm.selectedGradeName,
          items: vm.grades,
          label: "Assigned Class / Grade",
          hint: "Select grade level...",
          onChanged: (v) => vm.selectedGradeName = v,
        ),
        const SizedBox(height: 12),

        // Subjects picker
        InkWell(
          onTap: onPickSubjects,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundBlack,
              border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(77)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.textGrey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vm.selectedSubjects.isEmpty
                        ? "Select subjects (required)"
                        : "${vm.selectedSubjects.length} subject(s) selected",
                    style: TextStyle(
                      color: vm.selectedSubjects.isEmpty ? AppColors.textGrey : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textGrey),
              ],
            ),
          ),
        ),

        if (vm.selectedSubjects.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vm.selectedSubjects
                .map(
                  (s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: AppColors.surfaceLightGrey.withAlpha(40),
                    side: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(50)),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _GuardianSection extends StatelessWidget {
  final AddStudentViewModel vm;
  final bool isWide;
  const _GuardianSection({required this.vm, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "PAYER / GUARDIAN",
      icon: Icons.family_restroom_outlined,
      subtitle: "Receives reminders and settles invoices.",
      children: [
        _CompactTextField(
          controller: vm.guardianNameCtrl,
          label: "Full Name",
          hint: "Payer name",
          icon: Icons.person_outline,
          validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _Responsive2Col(
          isWide: isWide,
          left: _CompactTextField(
            controller: vm.guardianPhoneCtrl,
            label: "Phone",
            hint: "+263...",
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
            textInputAction: TextInputAction.next,
          ),
          right: _CompactTextField(
            controller: vm.guardianEmailCtrl,
            label: "Email (Optional)",
            hint: "name@email.com",
            icon: Icons.email_outlined,
            inputType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }
}

class _FinancialSection extends StatelessWidget {
  final AddStudentViewModel vm;
  final bool isWide;
  const _FinancialSection({required this.vm, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final openingDebt = vm.totalDebt;
    final initialPaid = vm.initialPay;
    final projectedInvoice = vm.projectedFirstInvoice;
    final netDue = vm.projectedNetDue;

    final bool hasDebt = openingDebt > 0;
    final bool invalidDeposit = (initialPaid > 0 && openingDebt <= 0 && projectedInvoice <= 0) ||
        (initialPaid > openingDebt + projectedInvoice);

    return _SectionCard(
      title: "FINANCIAL PROFILE",
      icon: Icons.account_balance_outlined,
      subtitle: "Defines billing cycle and opening balances. Offline-first safe.",
      borderColor: AppColors.primaryBlue.withAlpha(90),
      children: [
        _InfoBanner(
          tone: _BannerTone.info,
          title: "Billing Cycle",
          message: "This sets how the tuition billing engine will generate invoices (later).",
        ),
        const SizedBox(height: 10),

        _CompactDropdown(
          value: vm.selectedBillingCycle,
          items: vm.billingCycles,
          label: "Billing Cycle (Recurring)",
          hint: "How is this student billed?",
          onChanged: (v) => vm.selectedBillingCycle = (v ?? 'TERMLY'),
        ),

        const SizedBox(height: 14),
        const Divider(color: AppColors.surfaceLightGrey, thickness: 0.5),
        const SizedBox(height: 14),

        _InfoBanner(
          tone: _BannerTone.neutral,
          title: "Tuition Amount (Per Period)",
          message: "Used by auto-billing to create tuition invoices for this enrollment.",
        ),
        const SizedBox(height: 10),

        _MoneyField(
          controller: vm.tuitionAmountCtrl,
          label: "Tuition Amount",
          hint: "0.00",
          accent: AppColors.primaryBlue,
          validator: (v) {
            final val = (double.tryParse((v ?? '').trim()) ?? 0.0);
            if (val < 0) return "Cannot be negative";
            return null;
          },
        ),

        const SizedBox(height: 14),
        const Divider(color: AppColors.surfaceLightGrey, thickness: 0.5),
        const SizedBox(height: 14),

        _InfoBanner(
          tone: _BannerTone.neutral,
          title: "First Invoice",
          message: "Generate the first tuition invoice now to keep the ledger balanced.",
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(80)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Generate first invoice now",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: vm.generateInvoiceNow,
                activeColor: AppColors.primaryBlue,
                onChanged: (val) => vm.generateInvoiceNow = val,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        const Divider(color: AppColors.surfaceLightGrey, thickness: 0.5),
        const SizedBox(height: 14),

        _InfoBanner(
          tone: _BannerTone.neutral,
          title: "Opening Balance (Previous Debt)",
          message: "Only use this if the student is joining with an existing balance brought forward.",
        ),
        const SizedBox(height: 10),

        _Responsive2Col(
          isWide: isWide,
          left: _MoneyField(
            controller: vm.openingBalanceCtrl,
            label: "Opening Balance",
            hint: "0.00",
            accent: hasDebt ? AppColors.errorRed : Colors.white,
            validator: (v) {
              final val = (double.tryParse((v ?? '').trim()) ?? 0.0);
              if (val < 0) return "Cannot be negative";
              return null;
            },
          ),
          right: _CompactTextField(
            controller: vm.debtDescriptionCtrl,
            label: "Description (Recommended)",
            hint: "e.g. Term 1 arrears",
            validator: (_) => null,
            textInputAction: TextInputAction.next,
          ),
        ),

        const SizedBox(height: 14),
        const Divider(color: AppColors.surfaceLightGrey, thickness: 0.5),
        const SizedBox(height: 14),

        _InfoBanner(
          tone: _BannerTone.neutral,
          title: "Initial Payment (Deposit)",
          message: "Applied to Opening Balance first, then to the first invoice (if enabled).",
        ),
        const SizedBox(height: 10),

        _Responsive2Col(
          isWide: isWide,
          left: _MoneyField(
            controller: vm.initialPaymentCtrl,
            label: "Initial Payment",
            hint: "0.00",
            accent: AppColors.successGreen,
            validator: (v) {
              final val = (double.tryParse((v ?? '').trim()) ?? 0.0);
              if (val < 0) return "Cannot be negative";
              return null;
            },
          ),
          right: _CompactDropdown(
            value: vm.selectedPaymentMethod,
            items: vm.paymentMethods,
            label: "Payment Method",
            hint: "Select method...",
            onChanged: (v) => vm.selectedPaymentMethod = (v ?? 'Cash'),
          ),
        ),

        if (invalidDeposit) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            tone: _BannerTone.danger,
            title: "Fix Payment Inputs",
            message: (openingDebt <= 0 && projectedInvoice <= 0)
                ? "Initial Payment needs an Opening Balance or a First Invoice."
                : "Initial Payment cannot exceed Opening Balance plus the First Invoice.",
          ),
        ],

        const SizedBox(height: 14),

        // Summary block
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundBlack,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: invalidDeposit
                  ? AppColors.errorRed.withAlpha(130)
                  : AppColors.surfaceLightGrey.withAlpha(60),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("FINANCIAL SUMMARY", style: TextStyle(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _kv("Opening Balance", _money(openingDebt), valueColor: openingDebt > 0 ? AppColors.errorRed : Colors.white),
              const SizedBox(height: 6),
              _kv(
                "First Invoice",
                _money(projectedInvoice),
                valueColor: projectedInvoice > 0 ? AppColors.primaryBlueLight : Colors.white,
              ),
              const SizedBox(height: 6),
              _kv("Initial Payment", _money(initialPaid), valueColor: initialPaid > 0 ? AppColors.successGreen : Colors.white),
              const SizedBox(height: 6),
              const Divider(color: AppColors.surfaceLightGrey, thickness: 0.4),
              const SizedBox(height: 6),
              _kv(
                "Projected Balance",
                _money(netDue),
                valueColor: netDue <= 0 ? AppColors.successGreen : AppColors.errorRed,
                bold: true,
              ),
              const SizedBox(height: 6),
              Text(
                netDue <= 0 && (openingDebt > 0 || projectedInvoice > 0)
                    ? "Status: Cleared at admission"
                    : "Status: Balance carries forward",
                style: TextStyle(
                  color: netDue <= 0 && (openingDebt > 0 || projectedInvoice > 0)
                      ? AppColors.successGreen
                      : AppColors.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v, {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(color: Colors.white, fontSize: 13)),
        Text(
          v,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// DESKTOP SUMMARY PANEL
// -----------------------------------------------------------------------------
class _AdmissionSummaryPanel extends StatelessWidget {
  final AddStudentViewModel vm;
  const _AdmissionSummaryPanel({required this.vm});

  @override
  Widget build(BuildContext context) {
    final openingDebt = vm.totalDebt;
    final initialPaid = vm.initialPay;
    final projectedInvoice = vm.projectedFirstInvoice;
    final projectedTotal = vm.projectedTotalDue;

    final bool missingGrade = vm.selectedGradeName == null || vm.selectedGradeName!.trim().isEmpty;
    final bool missingSubjects = vm.selectedSubjects.isEmpty;
    final bool depositInvalid = (initialPaid > 0 && projectedTotal <= 0) ||
        (initialPaid > projectedTotal);

    final warnings = <String>[];
    if (missingGrade) warnings.add("Grade not selected");
    if (missingSubjects) warnings.add("No subjects selected");
    if (depositInvalid) {
      warnings.add(projectedTotal <= 0 ? "Initial Payment needs a balance or first invoice" : "Initial Payment exceeds total due");
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ADMISSION SUMMARY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          _summaryLine("Student", _safe("${vm.firstNameCtrl.text} ${vm.lastNameCtrl.text}".trim(), fallback: "—")),
          _summaryLine("Grade", _safe(vm.selectedGradeName, fallback: "—")),
          _summaryLine("Subjects", vm.selectedSubjects.isEmpty ? "—" : "${vm.selectedSubjects.length} selected"),
          _summaryLine("Billing Cycle", vm.selectedBillingCycle),
          const SizedBox(height: 10),
          const Divider(color: AppColors.surfaceLightGrey, thickness: 0.5),
          const SizedBox(height: 10),
          _summaryLine("Opening Balance", _money(vm.totalDebt)),
          _summaryLine("First Invoice", _money(vm.projectedFirstInvoice)),
          _summaryLine("Initial Payment", _money(vm.initialPay)),
          _summaryLine("Projected Balance", _money(vm.projectedNetDue)),
          const SizedBox(height: 12),
          if (warnings.isNotEmpty) ...[
            _InfoBanner(
              tone: _BannerTone.danger,
              title: "Blocking Issues",
              message: warnings.join(" • "),
            ),
          ] else ...[
            const _InfoBanner(
              tone: _BannerTone.success,
              title: "Ready",
              message: "Fields look consistent for admission.",
            ),
          ],
          const Spacer(),
          Text(
            "Tip: This screen is desktop-safe; it scales for Windows/Linux builds.",
            style: TextStyle(color: AppColors.textGrey.withAlpha(180), fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          Flexible(
            child: Text(
              v,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _safe(String? v, {required String fallback}) {
    final s = (v ?? '').trim();
    return s.isEmpty ? fallback : s;
  }
}

class _MiniSummaryLine extends StatelessWidget {
  final AddStudentViewModel vm;
  const _MiniSummaryLine({required this.vm});

  @override
  Widget build(BuildContext context) {
    final grade = (vm.selectedGradeName ?? '').trim();
    final subjects = vm.selectedSubjects.length;
    return Text(
      "${grade.isEmpty ? "No grade" : grade} • $subjects subject(s)",
      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// -----------------------------------------------------------------------------
// UI HELPERS
// -----------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  final Color? borderColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.surfaceLightGrey.withAlpha(35)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primaryBlueLight),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(color: AppColors.textGrey.withAlpha(200), fontSize: 12, height: 1.2),
              ),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Responsive2Col extends StatelessWidget {
  final bool isWide;
  final Widget left;
  final Widget right;

  const _Responsive2Col({required this.isWide, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType inputType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const _CompactTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.inputType = TextInputType.text,
    this.validator,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          validator: validator,
          textInputAction: textInputAction,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(120), fontSize: 13),
            prefixIcon: icon != null ? Icon(icon, size: 16, color: AppColors.textGrey) : null,
            filled: true,
            fillColor: AppColors.backgroundBlack,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(65)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorRed),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final Color? accent;
  final String? Function(String?)? validator;

  const _MoneyField({
    required this.controller,
    required this.label,
    this.hint,
    this.accent,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // 2 decimals max
    final formatters = <TextInputFormatter>[
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: formatters,
          validator: validator,
          style: TextStyle(color: accent ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixText: "\$ ",
            prefixStyle: TextStyle(color: AppColors.textGrey.withAlpha(200), fontWeight: FontWeight.w700),
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(120), fontSize: 13),
            filled: true,
            fillColor: AppColors.backgroundBlack,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(65)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorRed),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String label;
  final String? hint;
  final ValueChanged<String?> onChanged;

  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: (value != null && value!.isNotEmpty) ? value : null,
          hint: Text(hint ?? "Select...", style: TextStyle(color: AppColors.textGrey.withAlpha(120), fontSize: 13)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surfaceDarkGrey,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textGrey, size: 22),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundBlack,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(65)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// BANNERS
// -----------------------------------------------------------------------------
enum _BannerTone { info, neutral, danger, success }

class _InfoBanner extends StatelessWidget {
  final _BannerTone tone;
  final String title;
  final String message;

  const _InfoBanner({
    required this.tone,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    IconData icon;

    switch (tone) {
      case _BannerTone.info:
        border = AppColors.primaryBlue.withAlpha(90);
        bg = AppColors.primaryBlue.withAlpha(18);
        icon = Icons.info_outline;
        break;
      case _BannerTone.success:
        border = AppColors.successGreen.withAlpha(110);
        bg = AppColors.successGreen.withAlpha(18);
        icon = Icons.check_circle_outline;
        break;
      case _BannerTone.danger:
        border = AppColors.errorRed.withAlpha(120);
        bg = AppColors.errorRed.withAlpha(18);
        icon = Icons.warning_amber_rounded;
        break;
      case _BannerTone.neutral:
        border = AppColors.surfaceLightGrey.withAlpha(80);
        bg = AppColors.surfaceLightGrey.withAlpha(12);
        icon = Icons.tips_and_updates_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white.withAlpha(220)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.2),
                children: [
                  TextSpan(text: "$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUBJECT PICKER (kept local to avoid dependency conflicts for now)
// -----------------------------------------------------------------------------
class SubjectSelectionModal extends StatefulWidget {
  final List<String> allSubjects;
  final List<String> alreadySelected;

  const SubjectSelectionModal({super.key, required this.allSubjects, required this.alreadySelected});

  @override
  State<SubjectSelectionModal> createState() => _SubjectSelectionModalState();
}

class _SubjectSelectionModalState extends State<SubjectSelectionModal> {
  late List<String> _tempSelected;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.alreadySelected);
  }

  @override
  Widget build(BuildContext context) {
    final visibleSubjects = widget.allSubjects
        .where((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Subjects", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _tempSelected.clear()),
                      child: const Text("CLEAR", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _tempSelected),
                      child: const Text("DONE", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search subjects...",
                hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(140)),
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey, size: 20),
                filled: true,
                fillColor: AppColors.backgroundBlack,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: visibleSubjects.length,
              itemBuilder: (context, index) {
                final subject = visibleSubjects[index];
                final isSelected = _tempSelected.contains(subject);

                return CheckboxListTile(
                  title: Text(subject, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  value: isSelected,
                  activeColor: AppColors.primaryBlue,
                  checkColor: Colors.white,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _tempSelected.add(subject);
                      } else {
                        _tempSelected.remove(subject);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectsDialog extends StatelessWidget {
  final List<String> allSubjects;
  final List<String> alreadySelected;

  const _SubjectsDialog({required this.allSubjects, required this.alreadySelected});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDarkGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 720,
        height: 640,
        child: SubjectSelectionModal(allSubjects: allSubjects, alreadySelected: alreadySelected),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SMALL UTILS
// -----------------------------------------------------------------------------
String _money(double v) => "\$${v.toStringAsFixed(2)}";
