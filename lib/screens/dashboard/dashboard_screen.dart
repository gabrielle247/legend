import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/models/legend.dart';
import 'package:legend/repo/dashboard_repo.dart';
import 'package:legend/services/auth/auth_serv.dart';
import 'package:provider/provider.dart';

// -----------------------------------------------------------------------------
// VIEW MODEL (Data Container)
// -----------------------------------------------------------------------------
class DashboardViewModel {
  final LegendProfile profile;
  final DashboardStats stats;
  final List<Map<String, dynamic>> recentPayments;

  DashboardViewModel({
    required this.profile,
    required this.stats,
    required this.recentPayments,
  });

  // Empty State Factory (Safety Fallback)
  factory DashboardViewModel.empty() {
    return DashboardViewModel(
      profile: LegendProfile(id: "", fullName: "Staff Member", role: "STAFF"),
      stats: DashboardStats(
        totalStudents: 0,
        totalOwed: 0,
        collectedToday: 0,
        pendingInvoices: 0,
      ),
      recentPayments: [],
    );
  }
}

// -----------------------------------------------------------------------------
// DASHBOARD SCREEN UI
// -----------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardViewModel> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  /// --------------------------------------------------------------------------
  /// DATA LOADER (Real DB Fetching)
  /// --------------------------------------------------------------------------
  Future<DashboardViewModel> _loadData() async {
    final authService = context.read<AuthService>();
    final dashboardRepo = context.read<DashboardRepository>();

    final school = authService.activeSchool;
    final user = authService.user;

    // Safety Check: If logged out or no school selected
    if (school == null || user == null) {
      return DashboardViewModel.empty();
    }

    try {
      // PowerSync is already connected via AuthService.login()
      // Just fetch the data from local SQLite cache

      // 1. Fetch Data in Parallel (Fastest way)
      final results = await Future.wait([
        dashboardRepo.getDashboardStats(school.id),
        dashboardRepo.getRecentActivity(school.id),
      ]);

      final stats = results[0] as DashboardStats;
      final recentActivity = results[1] as List<Map<String, dynamic>>;

      // 2. Construct Profile from Auth Metadata
      // We check Supabase metadata for name, or fallback to email/default
      final String fullName =
          user.userMetadata?['full_name'] ??
          user.email?.split('@')[0] ??
          'Staff Member';

      final profile = LegendProfile(
        id: user.id,
        fullName: fullName,
        role: 'OWNER', // In future, fetch actual role from 'profiles' table
      );

      return DashboardViewModel(
        profile: profile,
        stats: stats,
        recentPayments: recentActivity,
      );
    } catch (e) {
      debugPrint("Dashboard Load Error: $e");
      return DashboardViewModel.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardViewModel>(
      future: _dataFuture,
      builder: (context, snapshot) {
        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }
        // 2. Error
        else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.errorRed,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }
        // 3. Data Ready
        else if (snapshot.hasData) {
          final data = snapshot.data!;
          return Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            appBar: _buildAppBar(context, data.profile),
            body: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.surfaceDarkGrey,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. WELCOME HEADER
                    _buildWelcomeHeader(data.profile),
                    const SizedBox(height: 24),

                    // 2. PRIMARY ACTION BUTTON
                    _buildPrimaryAction(context),
                    const SizedBox(height: 24),

                    // 3. FINANCIAL OVERVIEW CARD
                    _buildFinancialOverview(data.stats),
                    const SizedBox(height: 24),

                    // 4. STATS GRID
                    _buildStatsGrid(data.stats),
                    const SizedBox(height: 32),

                    // 5. RECENT PAYMENTS
                    _buildRecentPaymentsSection(context, data.recentPayments),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const Scaffold(body: Center(child: Text('No data')));
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    LegendProfile profile,
  ) {
    return AppBar(
      backgroundColor: AppColors.backgroundBlack,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            AppStrings.appName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () =>
              context.push('${AppRoutes.dashboard}/${AppRoutes.notifications}'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 8.0),
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.settings),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceLightGrey,
              // Initials from Name
              child: Text(
                profile.fullName.isNotEmpty
                    ? profile.fullName[0].toUpperCase()
                    : "U",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(LegendProfile profile) {
    // Get School Name safely
    final schoolName =
        context.read<AuthService>().activeSchool?.name ?? "KwaLegend Academy";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, ${profile.fullName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          schoolName,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () =>
            context.push('${AppRoutes.students}/${AppRoutes.addStudent}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add New Student',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Term Overview',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Financial Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildFinanceValueItem(
                  label: 'COLLECTED TODAY',
                  amount: stats.collectedToday,
                  color: AppColors.primaryBlue,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.surfaceLightGrey.withAlpha(50),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildFinanceValueItem(
                  label: 'TOTAL OWED',
                  amount: stats.totalOwed,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceValueItem({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enrollment Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Students',
                value: stats.totalStudents.toString(),
                subtext: 'Active Learners',
                icon: Icons.people_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Invoices',
                value: stats.pendingInvoices.toString(),
                subtext: 'Due this week',
                icon: Icons.description_outlined,
                isGrowth: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    bool isGrowth = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 6),
          Text(
            subtext,
            style: TextStyle(
              color: isGrowth ? Colors.greenAccent : AppColors.textGrey,
              fontSize: 12,
              fontWeight: isGrowth ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPaymentsSection(
    BuildContext context,
    List<Map<String, dynamic>> payments,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.push('${AppRoutes.finance}/transactions'),
              child: const Text(
                'View All',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPaymentList(payments),
      ],
    );
  }

  Widget _buildPaymentList(List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.history, color: AppColors.textGrey, size: 32),
            SizedBox(height: 8),
            Text(
              "No recent activity",
              style: TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final p = payments[i];
        final amount = (p['amount'] as num).toDouble();
        final isPayment = amount > 0; // Simple heuristic: Payments have value

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPayment
                      ? Colors.green.withAlpha(30)
                      : AppColors.primaryBlue.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPayment ? Icons.attach_money : Icons.person_add_alt_1,
                  color: isPayment ? Colors.greenAccent : AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p['desc']} • ${p['time']}',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPayment)
                Text(
                  '+\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
