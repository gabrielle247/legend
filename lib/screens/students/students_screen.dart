import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/models/students_models.dart';
import 'package:legend/services/auth/auth_serv.dart';
import 'package:legend/vmodels/students_vmodel.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  StudentListViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Initialize view model
    final authService = context.read<AuthService>();
    final schoolId = authService.activeSchool?.id ?? '';

    // Only initialize if we have a valid school
    if (schoolId.isNotEmpty) {
      _viewModel = StudentListViewModel(PowerSyncStudentRepository(), schoolId);
      // Load students
      _viewModel!.loadStudents();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI BUILDER
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // If no view model, show error state
    if (_viewModel == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'No active school found',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in again',
                style: TextStyle(color: AppColors.textGrey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _viewModel!,
      child: Consumer<StudentListViewModel>(
        builder: (context, vm, _) {
          // 1. FILTER LOGIC (reactive to vm)
          final allStudents = vm.students;
          final displayList = allStudents.where((student) {
            final name = student.fullName.toLowerCase();
            final adm = student.admissionNumber?.toLowerCase() ?? '';
            return name.contains(_searchQuery) || adm.contains(_searchQuery);
          }).toList();

          // 2. STATS CALCULATION (reactive to vm)
          double totalDebt = 0;
          int paidCount = 0;
          int owingCount = 0;

          for (var student in allStudents) {
            double bal = student.feesOwed;
            totalDebt += bal;
            if (bal <= 0) {
              paidCount++;
            } else {
              owingCount++;
            }
          }

          return Scaffold(
            backgroundColor: AppColors.backgroundBlack,

            // APP BAR
            appBar: AppBar(
              backgroundColor: AppColors.backgroundBlack,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: const Text(
                'Student Directory',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Filter coming soon'),
                        backgroundColor: AppColors.surfaceLightGrey,
                      ),
                    );
                  },
                ),
              ],
            ),

            // ADD BUTTON
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () =>
                  context.push('${AppRoutes.students}/${AppRoutes.addStudent}'),
              backgroundColor: AppColors.primaryBlue,
              elevation: 4,
              icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
              label: const Text(
                'Add Student',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // BODY (reactive)
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? _buildErrorState(vm.error!)
                : Column(
                    children: [
                      _buildStatsHeader(totalDebt, paidCount, owingCount),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search name or admission number...',
                            hintStyle: const TextStyle(
                              color: AppColors.textGrey,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.textGrey,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceDarkGrey,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: displayList.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  80,
                                ),
                                itemCount: displayList.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final student = displayList[index];
                                  return _buildStudentCard(student);
                                },
                              ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildStatsHeader(double totalDebt, int paidCount, int owingCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      height: 160, // Fixed height for chart area
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(50)),
      ),
      child: Row(
        children: [
          // LEFT: TEXT STATS
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Outstanding Debt",
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${totalDebt.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono', // Or default if not loaded
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildLegendDot(Colors.greenAccent, "Paid: $paidCount"),
                    const SizedBox(width: 12),
                    _buildLegendDot(AppColors.errorRed, "Owing: $owingCount"),
                  ],
                ),
              ],
            ),
          ),

          // RIGHT: FL_CHART
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 25,
                startDegreeOffset: -90,
                sections: [
                  // OWING SLICE (Red)
                  PieChartSectionData(
                    color: AppColors.errorRed,
                    value: owingCount.toDouble(),
                    title:
                        '${((owingCount / (owingCount + paidCount)) * 100).toInt()}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // PAID SLICE (Green)
                  PieChartSectionData(
                    color: Colors.greenAccent,
                    value: paidCount.toDouble(),
                    title: '', // Hide title for cleaner look if small
                    radius: 35, // Slightly smaller for effect
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.errorRed),
          const SizedBox(height: 16),
          Text(
            'Error loading students',
            style: TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _viewModel?.loadStudents(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textGrey.withAlpha(100),
          ),
          const SizedBox(height: 16),
          const Text(
            'No students found',
            style: TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    final double balance = student.feesOwed;
    final bool isPaidUp = balance <= 0;

    return InkWell(
      onTap: () => context.push('${AppRoutes.students}/view/${student.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceLightGrey.withAlpha(30),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryBlue.withAlpha(30),
              child: Text(
                _getInitials(student.fullName),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student.admissionNumber ?? 'No ADM'} • ${student.status.name}',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Balance Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isPaidUp
                    ? Colors.green.withAlpha(20)
                    : Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPaidUp ? 'PAID' : '-\$${balance.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isPaidUp ? Colors.greenAccent : AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}
