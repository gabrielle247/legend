// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/constants/app_strings.dart';
import 'package:legend/models/all_models.dart';
import 'package:legend/services/auth/auth.dart';
import 'package:legend/vmodels/students_vmodel.dart';
import 'package:provider/provider.dart';


// =============================================================================
// 3. SCREEN IMPLEMENTATION
// =============================================================================
class ViewStudentScreen extends StatefulWidget {
  final String? studentId;

  const ViewStudentScreen({super.key, this.studentId});

  @override
  State<ViewStudentScreen> createState() => _ViewStudentScreenState();
}

class _ViewStudentScreenState extends State<ViewStudentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StudentDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Get dependencies from context
    final authService = context.read<AuthService>();
    final repo = PowerSyncStudentRepository();
    final schoolId = authService.activeSchool?.id ?? '';

    _vm = StudentDetailViewModel(repo, schoolId);
    _load();
  }

  void _load() async {
    // Load student data - handle null gracefully
    final studentId = widget.studentId;
    if (studentId != null && studentId.isNotEmpty) {
      await _vm.loadStudent(studentId);
    } else {
      // Set error state if no studentId provided
      debugPrint('ERROR: No student ID provided to ViewStudentScreen');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getStatusText(StudentStatus status) {
    switch (status) {
      case StudentStatus.active:
        return "ACTIVE";
      case StudentStatus.suspended:
        return "SUSPENDED";
      case StudentStatus.alumni:
        return "ALUMNI";
      case StudentStatus.archived:
        return "ARCHIVED";
    }
  }

  String _getTypeText(StudentType type) {
    switch (type) {
      case StudentType.academy:
        return "Academy";
      case StudentType.private:
        return "Private";
    }
  }

  String? _getCurrentGrade() {
    // Get current grade from enrollments
    if (_vm.enrollments.isNotEmpty) {
      // Return the most recent active enrollment's grade level
      final activeEnrollment = _vm.enrollments.firstWhere(
        (e) => e.isActive,
        orElse: () => _vm.enrollments.first,
      );
      return activeEnrollment.gradeLevel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<StudentDetailViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.backgroundBlack,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),
            );
          }

          if (vm.student == null) {
            return Scaffold(
              backgroundColor: AppColors.backgroundBlack,
              appBar: AppBar(backgroundColor: AppColors.backgroundBlack),
              body: Center(
                child: Text(
                  vm.error ?? AppStrings.error,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 250.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.backgroundBlack,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                        onPressed: vm.student != null
                            ? () {
                                context.push(
                                  '${AppRoutes.students}/add?studentId=${vm.student!.id}',
                                );
                              }
                            : null,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildDigitalIdHeader(),
                    ),
                    bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primaryBlue,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textGrey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: AppStrings.tabOverview),
                        Tab(text: AppStrings.tabFinance),
                        Tab(text: AppStrings.tabAcademic),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildFinanceTab(),
                  _buildAcademicTab(),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment Gateway Init...")),
                );
              },
              backgroundColor: AppColors.successGreen,
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              label: const Text(
                AppStrings.actLogPayment,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // HEADER: DIGITAL ID CARD
  // ===========================================================================
  Widget _buildDigitalIdHeader() {
    final student = _vm.student!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlue.withAlpha(50),
            AppColors.backgroundBlack,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Hero(
              tag: 'student_avatar_${student.id}',
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundBlack,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withAlpha(100),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "${student.firstName[0]}${student.lastName[0]}",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Text Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.successGreen.withAlpha(100),
                      ),
                    ),
                    child: Text(
                      _getStatusText(student.status),
                      style: const TextStyle(
                        color: AppColors.successGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${student.firstName} ${student.lastName}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${AppStrings.lblAdmNum}: ${student.admissionNumber ?? 'N/A'}",
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _getCurrentGrade() ?? 'No Grade',
                    style: const TextStyle(
                      color: AppColors.primaryBlueLight,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

  // ===========================================================================
  // TAB 1: OVERVIEW
  // ===========================================================================
  Widget _buildOverviewTab() {
    final student = _vm.student!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.call_outlined,
                  label: AppStrings.actCall,
                  onTap:
                      () {}, // launchUrl("tel:${student.guardianPhone ?? ''}"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.message_outlined,
                  label: AppStrings.actWhatsApp,
                  onTap: () {},
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Identity
          _buildSectionHeader(AppStrings.secIdentity),
          _buildInfoCard([
            _InfoRow(
              AppStrings.lblDob,
              student.dob?.toString().split(' ')[0] ?? 'N/A',
            ),
            _InfoRow(AppStrings.lblGender, student.gender ?? 'N/A'),
            _InfoRow(AppStrings.lblType, _getTypeText(student.type)),
          ]),

          const SizedBox(height: 24),

          // Guardian
          _buildSectionHeader(AppStrings.secGuardian),
          _buildInfoCard([
            _InfoRow(
              AppStrings.lblRelation,
              student.guardianRelationship ?? 'N/A',
            ),
            _InfoRow("Name", student.guardianName ?? 'N/A'),
            _InfoRow(AppStrings.lblPhone, student.guardianPhone ?? 'N/A'),
          ]),

          const SizedBox(height: 80), // Fab space
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: FINANCE (The Ledger Style)
  // ===========================================================================
  Widget _buildFinanceTab() {
    final student = _vm.student!;
    final owed = student.feesOwed;
    final paid = 0.0; // TODO: Calculate from ledger
    final total = owed + paid;
    final progress = total == 0 ? 0.0 : paid / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FINANCIAL SUMMARY CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.surfaceLightGrey.withAlpha(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.lblOwed,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      "\$${owed.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: owed > 0
                            ? AppColors.errorRed
                            : AppColors.successGreen,
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
                    Text(
                      "${(progress * 100).toInt()}% Paid",
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Total Invoiced: \$${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(AppStrings.secLedger),

          // 2. TRANSACTION LIST (Placeholder)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                "Transaction history coming soon...",
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: ACADEMIC
  // ===========================================================================
  Widget _buildAcademicTab() {
    final enrollments = _vm.enrollments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Enrollments"),
          if (enrollments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  "No enrollments found",
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: enrollments.map((enrollment) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: enrollment.isActive
                        ? AppColors.primaryBlue.withAlpha(20)
                        : AppColors.surfaceLightGrey.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: enrollment.isActive
                          ? AppColors.primaryBlue.withAlpha(50)
                          : AppColors.surfaceLightGrey.withAlpha(50),
                    ),
                  ),
                  child: Text(
                    "${enrollment.gradeLevel}${enrollment.classStream != null ? ' ${enrollment.classStream}' : ''}",
                    style: TextStyle(
                      color: enrollment.isActive
                          ? AppColors.primaryBlueLight
                          : AppColors.textGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final btnColor = color ?? Colors.white;
    return Material(
      color: AppColors.surfaceDarkGrey,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
          ),
          child: Column(
            children: [
              Icon(icon, color: btnColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: btnColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value ?? "-",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String? value;
  _InfoRow(this.label, this.value);
}
