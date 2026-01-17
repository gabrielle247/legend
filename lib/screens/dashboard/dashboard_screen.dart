import 'package:legend/app_libs.dart';
import 'package:legend/data/constants/app_routes.dart'; // Imports everything

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    
    // SAFETY CHECK: Don't fetch data if we don't have a school yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      
      if (auth.activeSchool == null) {
        // Session isn't ready. Redirect to login to force a clean reload.
        context.go(AppRoutes.login);
      } else {
        // Session is good. Fetch data.
        context.read<DashboardViewModel>().init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, child) {
        
        // 1. LOADING STATE
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        // 2. ERROR STATE (With Session Recovery)
        if (vm.error != null) {
          final isSessionError = vm.error.toString().toLowerCase().contains('session');

          return Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSessionError ? Icons.lock_clock : Icons.error_outline, 
                      color: AppColors.errorRed, 
                      size: 48
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSessionError ? "Session Expired" : "Error Loading Dashboard",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.error!, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      // FIX: If session is dead, go to Login. If it's a network error, Retry.
                      onPressed: isSessionError 
                          ? () => _handleLogout(context)
                          : vm.refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSessionError ? AppColors.primaryBlue : AppColors.surfaceLightGrey,
                      ),
                      child: Text(isSessionError ? "Log In Again" : "Retry"),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 3. DATA READY
        final profile = vm.profile ?? LegendProfile(id: '0', fullName: 'Staff', role: 'STAFF');
        final stats = vm.stats; 

        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,
          appBar: _buildAppBar(context, profile),
          body: RefreshIndicator(
            onRefresh: vm.refresh,
            color: AppColors.primaryBlue,
            backgroundColor: AppColors.surfaceDarkGrey,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(context, profile),
                  const SizedBox(height: 24),
                  _buildPrimaryAction(context),
                  const SizedBox(height: 24),
                  _buildFinancialOverview(stats),
                  const SizedBox(height: 24),
                  _buildStatsGrid(stats),
                  const SizedBox(height: 32),
                  _buildRecentPaymentsSection(context, vm.recentActivity),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLogout(BuildContext context) async {
     await context.read<AuthService>().logout();
     if(mounted) context.go(AppRoutes.login);
  }

  // ---------------------------------------------------------------------------
  // WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, LegendProfile profile) {
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => context.push('/dashboard/notifications'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 8.0),
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.settings),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceLightGrey,
              child: Text(
                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : "U",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, LegendProfile profile) {
    final schoolName = context.read<AuthService>().activeSchool?.name ?? "KwaLegend Academy";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, ${profile.fullName}',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
        onPressed: () => context.push('/students/add'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add New Student',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
              const Text('Current Term Overview', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Financial Status', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildFinanceValueItem(label: 'COLLECTED TODAY', amount: stats.collectedToday, color: AppColors.primaryBlue)),
              Container(width: 1, height: 40, color: AppColors.surfaceLightGrey.withAlpha(50)),
              const SizedBox(width: 24),
              Expanded(child: _buildFinanceValueItem(label: 'TOTAL OWED', amount: stats.totalOwed, color: AppColors.errorRed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceValueItem({required String label, required double amount, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enrollment Stats', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(title: 'Total Students', value: stats.totalStudents.toString(), subtext: 'Active Learners', icon: Icons.people_outline)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(title: 'Pending Invoices', value: stats.pendingInvoices.toString(), subtext: 'Due this week', icon: Icons.description_outlined, isGrowth: false)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required String subtext, required IconData icon, bool isGrowth = true}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceDarkGrey, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: AppColors.textGrey, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtext, style: TextStyle(color: isGrowth ? Colors.greenAccent : AppColors.textGrey, fontSize: 12, fontWeight: isGrowth ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildRecentPaymentsSection(BuildContext context, List<Map<String, dynamic>> payments) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go(AppRoutes.finance),
              child: const Text('View All', style: TextStyle(color: AppColors.primaryBlue)),
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
        decoration: BoxDecoration(color: AppColors.surfaceDarkGrey.withAlpha(50), borderRadius: BorderRadius.circular(16)),
        child: const Column(
          children: [
            Icon(Icons.history, color: AppColors.textGrey, size: 32),
            SizedBox(height: 8),
            Text("No recent activity", style: TextStyle(color: AppColors.textGrey)),
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
        final isPayment = amount > 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surfaceDarkGrey, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isPayment ? Colors.green.withAlpha(30) : AppColors.primaryBlue.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: Icon(isPayment ? Icons.attach_money : Icons.person_add_alt_1, color: isPayment ? Colors.greenAccent : AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${p['desc']} • ${p['time']}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              if (isPayment)
                Text('+\$${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        );
      },
    );
  }
}