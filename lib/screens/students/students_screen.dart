import 'package:flutter/material.dart';
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/constants/app_strings.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/vmodels/students_vmodel.dart';
import 'package:legend/screens/students/add_student_screen.dart';
import 'package:legend/screens/students/view_student_screen.dart';
import 'package:provider/provider.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Load students on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentListViewModel>().loadStudents();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          ).then((_) {
            // Refresh list after adding
            context.read<StudentListViewModel>().loadStudents();
          });
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Student", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<StudentListViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text(vm.error!, style: const TextStyle(color: AppColors.textGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: vm.loadStudents,
                    child: const Text("Retry"),
                  )
                ],
              ),
            );
          }

          // Filter Logic
          final filteredStudents = vm.students.where((s) {
            final query = _searchQuery.toLowerCase();
            return s.firstName.toLowerCase().contains(query) ||
                s.lastName.toLowerCase().contains(query) ||
                (s.admissionNumber?.toLowerCase().contains(query) ?? false);
          }).toList();

          return CustomScrollView(
            slivers: [
              // 1. Header & Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.studentsTitle,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // THE STATS HEADER (Crash Fixed Here)
                      _buildStatsHeader(vm.students),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search students...",
                          hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                          prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: AppColors.surfaceDarkGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Student List
              if (filteredStudents.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.white.withAlpha(50)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? "No students yet." : "No matches found.",
                          style: TextStyle(color: Colors.white.withAlpha(100)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final student = filteredStudents[index];
                      return _StudentListItem(student: student);
                    },
                    childCount: filteredStudents.length,
                  ),
                ),
                
              // Padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CRASH FIX: SAFE STATS CALCULATION
  // ---------------------------------------------------------------------------
  Widget _buildStatsHeader(List<Student> students) {
    final totalStudents = students.length;
    final totalFeesOwed = students.fold(0.0, (sum, s) => sum + s.feesOwed);
    
    // Assume a mock collected amount for visual balance, or calculate from ledger if available
    // For this screen, we usually just show debt vs total count
    final activeCount = students.where((s) => s.status == StudentStatus.active).length;

    // Safety: If total is 0, percentage is 0. NEVER divide by zero.
    // This was the source of the "Infinity or NaN" crash.
    final debtPerStudent = totalStudents > 0 ? (totalFeesOwed / totalStudents) : 0.0;
    final activePercentage = totalStudents > 0 ? ((activeCount / totalStudents) * 100).toInt() : 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Total Students",
            value: totalStudents.toString(),
            icon: Icons.people,
            color: AppColors.primaryBlue,
            subtext: "$activePercentage% Active",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: "Total Debt",
            value: "\$${totalFeesOwed.toStringAsFixed(0)}",
            icon: Icons.money_off,
            color: AppColors.errorRed,
            subtext: "Avg: \$${debtPerStudent.toStringAsFixed(0)}",
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtext;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                subtext,
                style: TextStyle(
                  color: color.withAlpha(200),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentListItem extends StatelessWidget {
  final Student student;

  const _StudentListItem({required this.student});

  @override
  Widget build(BuildContext context) {
    final isArrears = student.feesOwed > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewStudentScreen(studentId: student.id),
            ),
          ).then((_) {
             // Refresh on return
             context.read<StudentListViewModel>().loadStudents();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: isArrears ? AppColors.errorRed : AppColors.successGreen,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.backgroundBlack,
                child: Text(
                  student.firstName[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
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
                      "${student.admissionNumber ?? 'No ID'} • ${student.gender ?? '-'}",
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isArrears ? "-\$${student.feesOwed.toStringAsFixed(0)}" : "Paid",
                    style: TextStyle(
                      color: isArrears ? AppColors.errorRed : AppColors.successGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      student.status.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}