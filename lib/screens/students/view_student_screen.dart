import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

    _detailVm = StudentDetailViewModel(studentRepo);

    final schoolId = auth.activeSchool?.id ?? '';

    if (widget.studentId != null) {
      _detailVm.loadStudent(widget.studentId!);
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
                      expandedHeight: 280, // Increased height for the new profile UI
                      pinned: true,
                      backgroundColor: AppColors.backgroundBlack,
                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.more_horiz, color: Colors.white),
                          onPressed: () => context.push('${AppRoutes.addStudent}?studentId=${student.id}'),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _StudentHeader(student: student, enrollments: vm.enrollments),
                      ),
                      bottom: const TabBar(
                        indicatorColor: AppColors.primaryBlue,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textGrey,
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: [
                          Tab(text: "Overview"),
                          Tab(text: "Finance"),
                          Tab(text: "Academic"),
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
          );
        },
      ),
    );
  }
}

// =============================================================================
// Header (Redesigned based on Image 2)
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
    final type = student.type.name.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        // Subtle top gradient to give depth
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            AppColors.primaryBlue.withAlpha(40),
            AppColors.backgroundBlack,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // Avatar with Status Dot
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryBlue.withAlpha(100), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.surfaceLightGrey,
                    child: Text(
                      "${student.firstName.isNotEmpty ? student.firstName[0] : ''}${student.lastName.isNotEmpty ? student.lastName[0] : ''}",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundBlack,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: student.status == StudentStatus.active ? AppColors.successGreen : AppColors.textGrey,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.backgroundBlack, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.successGreen.withAlpha(100)),
                  ),
                  child: Text(
                    student.status.name.toUpperCase(),
                    style: const TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Grade & Type Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeaderChip(text: grade, color: AppColors.primaryBlue),
                const SizedBox(width: 12),
                _HeaderChip(text: type, color: AppColors.surfaceLightGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String text;
  final Color color;
  const _HeaderChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

// =============================================================================
// Tab: Overview (Integrated Image 2 "Billing Core" & "Payer" UI)
// =============================================================================

class _OverviewTab extends StatelessWidget {
  final Student student;
  final List<Enrollment> enrollments;

  const _OverviewTab({required this.student, required this.enrollments});

  @override
  Widget build(BuildContext context) {
    final hasPhone = (student.guardianPhone ?? '').trim().isNotEmpty;
    final hasEmail = (student.guardianEmail ?? '').trim().isNotEmpty;

    // Define 'current' enrollment (active or first)
    final active = enrollments.where((e) => e.isActive).toList();
    final current = (active.isNotEmpty) ? active.first : (enrollments.isNotEmpty ? enrollments.first : null);

    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey("overview"),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionTitle(title: "BILLING CORE"),
                  const SizedBox(height: 12),
                  
                  // Admission Card (Matches Image 2 Top Card)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2029), // Slightly lighter than black
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("ADMISSION ID", style: TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            GestureDetector(
                              onTap: () => _copy(context, student.admissionNumber ?? ""),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLightGrey.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.copy, size: 12, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text("Copy", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          student.admissionNumber ?? "N/A",
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: AppColors.surfaceLightGrey.withAlpha(20)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailColumn(
                                label: "STUDENT TYPE",
                                value: student.type.name.capitalize(),
                                icon: Icons.school,
                              ),
                            ),
                            Expanded(
                              child: _DetailColumn(
                                label: "TUITION (PER PERIOD)",
                                value: current == null ? "N/A" : _money(current.tuitionAmount),
                                icon: Icons.payments_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle(title: "PRIMARY PAYER"),
                  const SizedBox(height: 12),

                  // Guardian Card (Matches Image 2 Bottom Card)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2029),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.surfaceLightGrey.withAlpha(50),
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.guardianName ?? "No Guardian",
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    student.guardianRelationship ?? 'Guardian',
                                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withAlpha(30),
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: const Text("GUARDIAN", style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionLargeBtn(
                                icon: Icons.phone,
                                label: "Call Mobile",
                                onTap: hasPhone ? () => _launchPhone(context, student.guardianPhone!) : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionLargeBtn(
                                icon: Icons.email,
                                label: "Send Email",
                                onTap: hasEmail ? () => _launchEmail(context, student.guardianEmail!, student.fullName) : null,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
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
      const SnackBar(content: Text("Copied info"), behavior: SnackBarBehavior.floating),
    );
  }

  static Future<void> _launchPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showLaunchError(context);
    }
  }

  static Future<void> _launchEmail(BuildContext context, String email, String studentName) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Guardian Contact: $studentName'},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showLaunchError(context);
    }
  }

  static void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Could not open the app."),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _money(double value) => "\$${value.toStringAsFixed(2)}";
}

class _DetailColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DetailColumn({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textGrey),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionLargeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionLargeBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? AppColors.backgroundBlack : AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: enabled ? AppColors.textGrey : AppColors.surfaceLightGrey, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tab: Finance (Integrated Image 1 UI)
// =============================================================================

class _FinanceTab extends StatelessWidget {
  final Student student;
  const _FinanceTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final financeVm = context.watch<StudentFinanceViewModel?>();

    if (financeVm == null || financeVm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    final invoices = financeVm.invoices;
    final payments = financeVm.payments;
    final totalInvoiced = invoices.fold<double>(0.0, (s, i) => s + i.totalAmount);
    final totalPaid = payments.fold<double>(0.0, (s, p) => s + p.amount);
    final outstanding = (totalInvoiced - totalPaid) < 0 ? 0.0 : (totalInvoiced - totalPaid);
    final progress = totalInvoiced <= 0 ? 0.0 : (totalPaid / totalInvoiced).clamp(0.0, 1.0);
    final nextDueDate = _nextDueDate(invoices);
    final hasGuardianPhone = (student.guardianPhone ?? '').trim().isNotEmpty;
    final hasGuardianEmail = (student.guardianEmail ?? '').trim().isNotEmpty;

    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey("finance"),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  
                  // Big Outstanding Card (Image 1 Style)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2029),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TOTAL OUTSTANDING", style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            Icon(Icons.wallet, color: AppColors.surfaceLightGrey.withAlpha(50), size: 32)
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\$${outstanding.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono'),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("PAYMENT PLAN PROGRESS", style: TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("${(progress * 100).toInt()}% PAID", style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.backgroundBlack,
                            color: AppColors.primaryBlue,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Paid: \$${totalPaid.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                            Text("Total: \$${totalInvoiced.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (hasGuardianPhone || hasGuardianEmail) ...[
                          const SizedBox(height: 20),
                          _NotificationActions(
                            student: student,
                            outstanding: outstanding,
                            nextDueDate: nextDueDate,
                            hasGuardianEmail: hasGuardianEmail,
                            hasGuardianPhone: hasGuardianPhone,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('${AppRoutes.finance}/${AppRoutes.loggingPayments}'.replaceAll(':studentId', student.id)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.receipt_long, size: 18),
                          label: const Text("Log Payment", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('${AppRoutes.students}/${AppRoutes.studentLogs}'.replaceAll(':studentId', student.id)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(40)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text("Student Logs"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(title: "RECENT INVOICES"),
                      GestureDetector(
                        onTap: () => context.go(
                          '${AppRoutes.students}/${AppRoutes.studentInvoices}'.replaceAll(':studentId', student.id),
                        ),
                        child: const Text("See All", style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (invoices.isEmpty)
                     const Padding(padding: EdgeInsets.all(20), child: Text("No invoices found.", style: TextStyle(color: AppColors.textGrey)))
                  else
                    ...invoices.take(3).map((inv) => _InvoiceTile(inv: inv)),

                  const SizedBox(height: 24),
                  _SectionTitle(title: "PAYMENT HISTORY"),
                  const SizedBox(height: 16),
                  
                  if (payments.isEmpty)
                     const Padding(padding: EdgeInsets.all(20), child: Text("No payments found.", style: TextStyle(color: AppColors.textGrey)))
                  else
                    ...payments.take(3).map((p) => _PaymentTile(p: p)),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  DateTime? _nextDueDate(List<Invoice> invoices) {
    final unpaid = invoices.where((i) => i.status != InvoiceStatus.paid).toList();
    if (unpaid.isEmpty) return null;
    unpaid.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return unpaid.first.dueDate;
  }
}

class _NotificationActions extends StatelessWidget {
  final Student student;
  final double outstanding;
  final DateTime? nextDueDate;
  final bool hasGuardianPhone;
  final bool hasGuardianEmail;

  const _NotificationActions({
    required this.student,
    required this.outstanding,
    required this.nextDueDate,
    required this.hasGuardianEmail,
    required this.hasGuardianPhone,
  });

  @override
  Widget build(BuildContext context) {
    final message = _buildMessage();
    return Row(
      children: [
        if (hasGuardianPhone)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _launchWhatsApp(context, message),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text("WhatsApp Parent"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (hasGuardianPhone && hasGuardianEmail) const SizedBox(width: 12),
        if (hasGuardianEmail)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launchEmail(context, message),
              icon: const Icon(Icons.alternate_email, size: 18),
              label: const Text("Email Parent"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue.withAlpha(120)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
      ],
    );
  }

  String _buildMessage() {
    final studentName = student.fullName;
    final dueText = _dueText();
    final billing = student.billingCycle.trim().isEmpty ? "" : "Billing cycle: ${student.billingCycle}.";
    return "Hello ${student.guardianName ?? 'Parent'}, $studentName owes \$${outstanding.toStringAsFixed(2)}. $dueText $billing";
  }

  String _dueText() {
    if (nextDueDate == null) return "No due date set.";
    final date = nextDueDate!.toIso8601String().split('T')[0];
    final days = nextDueDate!.difference(DateTime.now()).inDays;
    if (days < 0) return "Due date: $date (overdue).";
    if (days == 0) return "Due date: $date (today).";
    if (days <= 7) return "Due date: $date (in $days days).";
    return "Due date: $date.";
  }

  Future<void> _launchWhatsApp(BuildContext context, String message) async {
    final phone = (student.guardianPhone ?? '').replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showLaunchError(context);
    }
  }

  Future<void> _launchEmail(BuildContext context, String message) async {
    final email = (student.guardianEmail ?? '').trim();
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Payment Reminder: ${student.fullName}',
        'body': message,
      },
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Could not open messaging app."),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice inv;
  const _InvoiceTile({required this.inv});

  @override
  Widget build(BuildContext context) {
    final statusColor = inv.status == InvoiceStatus.paid ? AppColors.successGreen : Colors.orange;
    return InkWell(
      onTap: () => context.push(
        '${AppRoutes.finance}/${AppRoutes.viewInvoice}'.replaceAll(':invoiceId', inv.id),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2029),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.title ?? "Invoice", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text("Due ${inv.dueDate.toIso8601String().split('T')[0]}", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("\$${inv.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(inv.status.name.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment p;
  const _PaymentTile({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2029),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.credit_card, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Payment • ${p.method}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(p.receivedAt.toIso8601String().split('T')[0], style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("\$${p.amount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              const Text("Success", style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

// =============================================================================
// Tab: Academic (Integrated Image 3 "Journey" & "Subject List" UI)
// =============================================================================

class _AcademicTab extends StatelessWidget {
  final List<Enrollment> enrollments;
  const _AcademicTab({required this.enrollments});

  @override
  Widget build(BuildContext context) {
    final active = enrollments.where((e) => e.isActive).toList();
    final current = (active.isNotEmpty) ? active.first : (enrollments.isNotEmpty ? enrollments.first : null);
    
    // Calculate Journey Duration
    final start = current?.enrollmentDate ?? current?.createdAt;
    final duration = start == null ? null : DateTime.now().difference(start);
    final years = duration == null ? 0 : (duration.inDays / 365).floor();
    final months = duration == null ? 0 : ((duration.inDays % 365) / 30).floor();
    final timeStr = duration == null ? "Unknown" : (years > 0 ? "$years Yrs, $months Mos" : "$months Mos");

    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey("academic"),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionTitle(title: "STUDENT JOURNEY"),
                  const SizedBox(height: 12),

                  // Journey Card (Image 3 Style)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2029),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TIME WITH SCHOOL", style: TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withAlpha(20),
                                shape: BoxShape.circle
                              ),
                              child: const Icon(Icons.school, size: 16, color: AppColors.primaryBlue),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("ENROLLED", style: TextStyle(color: AppColors.textGrey, fontSize: 10)),
                                const SizedBox(height: 4),
                                Text(
                                  start != null ? start.toIso8601String().split('T')[0] : "Unknown",
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(title: "CURRENT SUBJECT ENROLLMENT"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLightGrey.withAlpha(20),
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text("Term 1 - ${DateTime.now().year}", style: const TextStyle(color: AppColors.textGrey, fontSize: 10)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (current?.subjects.isEmpty ?? true)
                     const Padding(padding: EdgeInsets.all(20), child: Text("No subjects enrolled.", style: TextStyle(color: AppColors.textGrey)))
                  else
                    ...current!.subjects.map((sub) => _SubjectTile(subject: sub)),

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

class _SubjectTile extends StatelessWidget {
  final String subject;
  const _SubjectTile({required this.subject});

  IconData _getIcon(String s) {
    final l = s.toLowerCase();
    if (l.contains("math")) return Icons.calculate;
    if (l.contains("sci") || l.contains("chem") || l.contains("bio") || l.contains("phys")) return Icons.science;
    if (l.contains("lit") || l.contains("eng")) return Icons.menu_book;
    if (l.contains("art") || l.contains("music")) return Icons.music_note;
    if (l.contains("sport") || l.contains("gym")) return Icons.sports_soccer;
    return Icons.book;
  }

  Color _getColor(String s) {
    final l = s.toLowerCase();
    if (l.contains("math")) return Colors.blueAccent;
    if (l.contains("lit")) return Colors.purpleAccent;
    if (l.contains("chem")) return Colors.orangeAccent;
    if (l.contains("sport")) return Colors.greenAccent;
    return AppColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(subject);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2029),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(subject), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const Text("Core • Tuition Included", style: TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: AppColors.surfaceLightGrey.withAlpha(50), size: 18)
        ],
      ),
    );
  }
}

// =============================================================================
// Shared Helpers
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
