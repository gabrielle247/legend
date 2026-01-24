import 'package:legend/app_libs.dart';
import 'package:legend/data/constants/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.activeSchool == null) {
        context.go(AppRoutes.login);
      } else {
        context.read<DashboardViewModel>().init();
      }
    });
  }

  // LOGIC: Time-aware greeting
  String get _timeAwareGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, child) {
        // 1. LOADING
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
          );
        }

        // 2. ERROR
        if (vm.error != null) {
          final isSessionError = vm.error.toString().toLowerCase().contains('session');
          return Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isSessionError ? Icons.lock_clock : Icons.error_outline, color: AppColors.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text(vm.error!, style: const TextStyle(color: AppColors.textGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSessionError ? () => _handleLogout(context) : vm.refresh,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                    child: Text(isSessionError ? "Log In Again" : "Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        // 3. DATA
        final profile = vm.profile ?? LegendProfile(id: '0', fullName: 'Staff', role: 'STAFF');
        final stats = vm.stats;
        final unreadStream = vm.unreadCountStream;

        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,
          
          // APP BAR (Hidden/Minimal to let greeting shine)
          appBar: AppBar(
            backgroundColor: AppColors.backgroundBlack,
            elevation: 0,
            toolbarHeight: 0,
          ),

          // BODY (Pure content, no NavBars or FABs here)
          body: RefreshIndicator(
            onRefresh: vm.refresh,
            color: AppColors.primaryBlue,
            backgroundColor: AppColors.surfaceDarkGrey,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Padding bottom 100 to ensure content isn't hidden behind the AppShell's GNav
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(context, profile, unreadStream),
                  const SizedBox(height: 24),
                  _buildMonthlyCollectionCard(context, stats),
                  const SizedBox(height: 24),
                  const Text("Quick Actions", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Activity", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.finance),
                        child: const Text("View Ledger", style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActivityCard(
                          context,
                          label: "RECEIVED",
                          amount: stats.collectedToday,
                          icon: Icons.arrow_downward,
                          color: AppColors.successGreen,
                          onTap: () => context.go('${AppRoutes.dashboard}/${AppRoutes.received}'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActivityCard(
                          context,
                          label: "OUTSTANDING",
                          amount: stats.totalOwed,
                          icon: Icons.more_horiz,
                          color: Colors.orangeAccent,
                          onTap: () => context.go('${AppRoutes.dashboard}/${AppRoutes.outstanding}'),
                        ),
                      ),
                    ],
                  ),
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
    if (mounted) context.go(AppRoutes.login);
  }

  // ---------------------------------------------------------------------------
  // WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeHeader(
    BuildContext context,
    LegendProfile profile,
    Stream<int>? unreadStream,
  ) {
    final schoolName = context.read<AuthService>().activeSchool?.name ?? "—";
    final displayName = profile.fullName.trim().isEmpty ? "Staff" : profile.fullName.split(' ').first;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_timeAwareGreeting, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
            const SizedBox(height: 4),
            Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(schoolName, style: TextStyle(color: AppColors.primaryBlue.withAlpha(200), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          children: [
            _buildNotificationsButton(context, unreadStream),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => context.go(AppRoutes.settings),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryBlue, width: 2)),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceLightGrey,
                  child: Text(profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : "U", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildNotificationsButton(BuildContext context, Stream<int>? unreadStream) {
    final iconButton = IconButton(
      onPressed: () => context.go('${AppRoutes.dashboard}/${AppRoutes.notifications}'),
      icon: const Icon(Icons.notifications_none, color: Colors.white),
      tooltip: "Notifications",
    );

    if (unreadStream == null) return iconButton;

    return StreamBuilder<int>(
      stream: unreadStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count <= 0) return iconButton;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            iconButton,
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count > 99 ? "99+" : "$count",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthlyCollectionCard(BuildContext context, DashboardStats stats) {
    return Material(
      color: AppColors.surfaceDarkGrey,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => context.go(AppRoutes.finance),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
          ),
          child: Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_outlined, color: AppColors.primaryBlue, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Collection", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("\$${stats.collectedToday.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.primaryBlue, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Outstanding: \$${stats.totalOwed.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.payments_outlined,
            label: "Log\nPayment",
            onTap: () => context.go('${AppRoutes.finance}/${AppRoutes.recordPayment}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(context, icon: Icons.person_add_alt_1, label: "Add\nStudent", onTap: () => context.go('${AppRoutes.students}/${AppRoutes.addStudent}'))),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(context, icon: Icons.bar_chart, label: "Run\nReports", onTap: () => context.push('${AppRoutes.dashboard}/${AppRoutes.statistics}'))),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: AppColors.surfaceDarkGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppColors.primaryBlue, size: 24), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, {required String label, required double amount, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: AppColors.surfaceDarkGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 8), Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
              const SizedBox(height: 12),
              Text("\$${amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPaymentsSection(BuildContext context, List<Map<String, dynamic>> payments) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go('${AppRoutes.dashboard}/${AppRoutes.activity}'),
              child: const Text('View All', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
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
        child: const Center(child: Text("No recent activity", style: TextStyle(color: AppColors.textGrey))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length > 5 ? 5 : payments.length,
      itemBuilder: (ctx, i) {
        final p = payments[i];
        final amount = (p['amount'] as num).toDouble();
        final isPayment = amount > 0;
        final name = p['name'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surfaceDarkGrey, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surfaceLightGrey.withAlpha(50),
                radius: 18,
                child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${p['desc']}', style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                isPayment ? '+\$${amount.toStringAsFixed(0)}' : '\$${amount.abs().toStringAsFixed(0)}',
                style: TextStyle(color: isPayment ? AppColors.successGreen : AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ],
          ),
        );
      },
    );
  }
}
