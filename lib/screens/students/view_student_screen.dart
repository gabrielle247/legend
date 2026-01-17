import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/constants/app_routes.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/repo/student_repo.dart';
import 'package:legend/data/services/auth/auth.dart';
import 'package:legend/data/vmodels/students_vmodel.dart';

class ViewStudentScreen extends StatefulWidget {
  final String? studentId;
  const ViewStudentScreen({super.key, this.studentId});

  @override
  State<ViewStudentScreen> createState() => _ViewStudentScreenState();
}

class _ViewStudentScreenState extends State<ViewStudentScreen> {
  late final StudentDetailViewModel _detailVm;
  StudentFinanceViewModel? _financeVm;

  @override
  void initState() {
    super.initState();

    final auth = context.read<AuthService>();
    final studentRepo = context.read<StudentRepository>();
    final financeRepo = context.read<FinanceRepository>();

    // IMPORTANT: Your error says you’re passing too many args to the VM.
    // So we construct using ONLY repo (1 positional).
    _detailVm = StudentDetailViewModel(studentRepo);

    final schoolId = auth.activeSchool?.id ?? '';

    if (widget.studentId != null) {
      // Detail
      _detailVm.loadStudent(widget.studentId!);

      // Finance (real data)
      _financeVm = StudentFinanceViewModel(financeRepo, widget.studentId!, schoolId);
      _financeVm!.loadFinanceData();
    }
  }

  @override
  void dispose() {
    _detailVm.dispose();
    _financeVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StudentDetailViewModel>.value(value: _detailVm),
        if (_financeVm != null)
          ChangeNotifierProvider<StudentFinanceViewModel>.value(value: _financeVm!),
      ],
      child: Consumer<StudentDetailViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.backgroundBlack,
              body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
            );
          }

          if (vm.student == null) {
            return Scaffold(
              backgroundColor: AppColors.backgroundBlack,
              appBar: AppBar(
                backgroundColor: AppColors.backgroundBlack,
                leading: const BackButton(color: Colors.white),
              ),
              body: const Center(
                child: Text("Student not found", style: TextStyle(color: Colors.white)),
              ),
            );
          }

          final student = vm.student!;
          return Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: DefaultTabController(
              length: 3,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    sliver: SliverAppBar(
                      expandedHeight: 220,
                      pinned: true,
                      backgroundColor: AppColors.backgroundBlack,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => context.push('${AppRoutes.addStudent}?studentId=${student.id}'),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _StudentHeader(student: student, enrollments: vm.enrollments),
                      ),
                      bottom: const TabBar(
                        indicatorColor: AppColors.primaryBlue,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textGrey,
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: [
                          Tab(text: "OVERVIEW"),
                          Tab(text: "FINANCE"),
                          Tab(text: "ACADEMIC"),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _OverviewTab(student: student, enrollments: vm.enrollments),
                    _FinanceTab(student: student),
                    _AcademicTab(enrollments: vm.enrollments),
                  ],
                ),
              ),
            ),

            // No placebo: log payment screen not built -> disable + clearly label.
            floatingActionButton: _LogPaymentFab(student: student),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Header
// =============================================================================

class _StudentHeader extends StatelessWidget {
  final Student student;
  final List<Enrollment> enrollments;

  const _StudentHeader({required this.student, required this.enrollments});

  @override
  Widget build(BuildContext context) {
    final active = enrollments.where((e) => e.isActive).toList();
    final current = (active.isNotEmpty) ? active.first : (enrollments.isNotEmpty ? enrollments.first : null);

    final grade = current?.gradeLevel ?? "No Grade";
    final stream = (current?.classStream?.trim().isNotEmpty ?? false) ? " • ${current!.classStream}" : "";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBlue.withAlpha(40), AppColors.backgroundBlack],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Hero(
              tag: 'avatar_${student.id}',
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  "${student.firstName.isNotEmpty ? student.firstName[0] : '?'}"
                  "${student.lastName.isNotEmpty ? student.lastName[0] : '?'}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              student.fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatusChip(text: "$grade$stream", color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                _StatusChip(
                  text: student.status.name.toUpperCase(),
                  color: student.status == StudentStatus.active ? AppColors.successGreen : AppColors.textGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tab: Overview (no dead actions; real utilities)
// =============================================================================

class _OverviewTab extends StatelessWidget {
  final Student student;
  final List<Enrollment> enrollments;

  const _OverviewTab({required this.student, required this.enrollments});

  String _prettyGender(String? g) {
    final s = (g ?? '').trim();
    if (s.isEmpty) return "N/A";
    final v = s.toLowerCase();
    if (v.startsWith('m')) return "Male";
    if (v.startsWith('f')) return "Female";
    return s; // don’t guess beyond this
  }

  @override
  Widget build(BuildContext context) {
    final active = enrollments.where((e) => e.isActive).toList();
    final current = (active.isNotEmpty) ? active.first : (enrollments.isNotEmpty ? enrollments.first : null);

    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey("overview"),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Real actions: copy key values (no external packages)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ActionBtn(
                        icon: Icons.copy,
                        label: "Copy Admission ID",
                        onTap: () => _copy(context, student.admissionNumber ?? "N/A"),
                      ),
                      _ActionBtn(
                        icon: Icons.copy,
                        label: "Copy Guardian Phone",
                        color: AppColors.successGreen,
                        onTap: () => _copy(context, student.guardianPhone ?? "N/A"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _SectionHeader(title: "IDENTITY"),
                  _InfoCard(
                    children: [
                      _InfoRow("Admission ID", student.admissionNumber ?? "N/A"),
                      _InfoRow("Gender", _prettyGender(student.gender)),
                      _InfoRow("Type", student.type.name.toUpperCase()),
                      _InfoRow("Status", student.status.name.toUpperCase()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _SectionHeader(title: "CURRENT ENROLLMENT"),
                  _InfoCard(
                    children: [
                      _InfoRow("Grade Level", current?.gradeLevel ?? "N/A"),
                      _InfoRow("Stream", current?.classStream ?? "N/A"),
                      _InfoRow(
                        "Enrollment Date",
                        (current?.enrollmentDate ?? current?.createdAt)?.toIso8601String() ?? "N/A",
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _SectionHeader(title: "GUARDIAN"),
                  _InfoCard(
                    children: [
                      _InfoRow("Name", student.guardianName ?? "N/A"),
                      _InfoRow("Phone", student.guardianPhone ?? "N/A"),
                      _InfoRow("Email", student.guardianEmail ?? "N/A"),
                      _InfoRow("Relation", student.guardianRelationship ?? "N/A"),
                    ],
                  ),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// =============================================================================
// Tab: Finance (NO PLACEBO: real invoices + payments)
// =============================================================================

class _FinanceTab extends StatelessWidget {
  final Student student;
  const _FinanceTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final financeVm = context.watch<StudentFinanceViewModel?>();

    if (financeVm == null) {
      return const Center(
        child: Text("Finance context unavailable.", style: TextStyle(color: AppColors.textGrey)),
      );
    }

    if (financeVm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (financeVm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(financeVm.error!, style: const TextStyle(color: AppColors.errorRed)),
        ),
      );
    }

    final invoices = financeVm.invoices;
    final payments = financeVm.payments;

    final totalInvoiced = invoices.fold<double>(0.0, (s, i) => s + i.totalAmount);
    final totalPaid = payments.fold<double>(0.0, (s, p) => s + p.amount);

    // Computed outstanding from records
    final computedOutstanding = (totalInvoiced - totalPaid) < 0 ? 0.0 : (totalInvoiced - totalPaid);

    // Your system also maintains student.fees_owed; detect mismatch (no silent failure)
    final storedOutstanding = student.feesOwed;
    final delta = (storedOutstanding - computedOutstanding).abs();
    final mismatch = delta > 0.01;

    final progress = totalInvoiced <= 0 ? 0.0 : (totalPaid / totalInvoiced).clamp(0.0, 1.0);

    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey("finance"),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _FinanceSummaryCard(
                    outstanding: storedOutstanding,
                    computedOutstanding: computedOutstanding,
                    totalInvoiced: totalInvoiced,
                    totalPaid: totalPaid,
                    progress: progress,
                    mismatch: mismatch,
                  ),

                  const SizedBox(height: 16),

                  if (mismatch)
                    _WarningCard(
                      title: "DATA MISMATCH DETECTED",
                      body:
                          "student.fees_owed = \$${storedOutstanding.toStringAsFixed(2)} "
                          "but invoices-payments = \$${computedOutstanding.toStringAsFixed(2)}.\n"
                          "This will cause screens to disagree unless you reconcile.",
                    ),

                  const SizedBox(height: 24),
                  _SectionHeader(title: "INVOICES"),
                  if (invoices.isEmpty)
                    const _EmptyHint(text: "No invoices found for this student.")
                  else
                    ...invoices.map((inv) => _InvoiceRow(inv: inv)),

                  const SizedBox(height: 24),
                  _SectionHeader(title: "PAYMENTS"),
                  if (payments.isEmpty)
                    const _EmptyHint(text: "No payments recorded for this student.")
                  else
                    ...payments.map((p) => _PaymentRow(p: p)),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FinanceSummaryCard extends StatelessWidget {
  final double outstanding;
  final double computedOutstanding;
  final double totalInvoiced;
  final double totalPaid;
  final double progress;
  final bool mismatch;

  const _FinanceSummaryCard({
    required this.outstanding,
    required this.computedOutstanding,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.progress,
    required this.mismatch,
  });

  @override
  Widget build(BuildContext context) {
    final danger = outstanding > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Outstanding Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                "\$${outstanding.toStringAsFixed(2)}",
                style: TextStyle(
                  color: danger ? AppColors.errorRed : AppColors.successGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceLightGrey.withAlpha(50),
              color: AppColors.successGreen,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${(progress * 100).toInt()}% Paid", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              Text("Invoiced: \$${totalInvoiced.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Paid: \$${totalPaid.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              Text(
                mismatch ? "Check: FAIL" : "Check: OK",
                style: TextStyle(
                  color: mismatch ? AppColors.errorRed : AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Computed outstanding (invoices - payments): \$${computedOutstanding.toStringAsFixed(2)}",
            style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice inv;
  const _InvoiceRow({required this.inv});

  @override
  Widget build(BuildContext context) {
    final status = inv.status.name.toUpperCase();
    final due = inv.dueDate.toIso8601String().split('T').first;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(inv.title ?? inv.invoiceNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Due: $due • $status", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ]),
          ),
          Text(
            "\$${inv.totalAmount.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Payment p;
  const _PaymentRow({required this.p});

  @override
  Widget build(BuildContext context) {
    final date = p.receivedAt.toIso8601String().split('T').first;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Payment • ${p.method}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Date: $date", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              if ((p.reference ?? '').trim().isNotEmpty)
                Text("Ref: ${p.reference}", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ]),
          ),
          Text(
            "\$${p.amount.toStringAsFixed(2)}",
            style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab: Academic (subjects now come from Enrollment.subjects JSON)
// =============================================================================

class _AcademicTab extends StatelessWidget {
  final List<Enrollment> enrollments;
  const _AcademicTab({required this.enrollments});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey("academic"),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final e = enrollments[index];
                  final date = (e.enrollmentDate ?? e.createdAt)?.toIso8601String().split('T').first ?? "N/A";
                  final subjects = e.subjects;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDarkGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: e.isActive ? AppColors.primaryBlue.withAlpha(80) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.gradeLevel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (e.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primaryBlue.withAlpha(80)),
                                ),
                                child: const Text(
                                  "ACTIVE",
                                  style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("Enrollment Date: $date", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                        if ((e.classStream ?? '').trim().isNotEmpty)
                          Text("Stream: ${e.classStream}", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),

                        const SizedBox(height: 12),
                        const Text(
                          "SUBJECTS",
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (subjects.isEmpty)
                          const Text("No subjects recorded.", style: TextStyle(color: AppColors.textGrey, fontSize: 12))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: subjects
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundBlack,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(40)),
                                      ),
                                      child: Text(
                                        s,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  );
                }, childCount: enrollments.length),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// No placebo FAB: disabled but explicit
// =============================================================================

class _LogPaymentFab extends StatelessWidget {
  final Student student;
  const _LogPaymentFab({required this.student});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: null, // disabled on purpose (not fake)
      backgroundColor: AppColors.surfaceLightGrey,
      icon: const Icon(Icons.payments_outlined, color: Colors.white54),
      label: const Text(
        "LOG PAYMENT (NEXT)",
        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// =============================================================================
// Shared helpers
// =============================================================================

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Material(
      color: AppColors.surfaceDarkGrey,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text, style: const TextStyle(color: AppColors.textGrey))),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String title;
  final String body;
  const _WarningCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
