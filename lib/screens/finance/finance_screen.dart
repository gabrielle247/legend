import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/constants/app_routes.dart';
import 'package:legend/data/vmodels/finance_vmodel.dart';
import 'package:provider/provider.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().init();
    });
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION HANDLERS
  // ---------------------------------------------------------------------------
  void _navToCreateInvoice() => context.push('${AppRoutes.finance}/${AppRoutes.createInvoice}');
  void _navToRecordPayment() => context.push('${AppRoutes.finance}/${AppRoutes.recordPayment}');
  
  void _navToStudentIfPossible(Map<String, dynamic> item) {
    final targetId = item['targetId']?.toString();
    if (targetId != null && targetId.isNotEmpty) {
      context.push('${AppRoutes.students}/view/$targetId');
    } else {
      // TODO: Handle navigation for non-student transactions (e.g. operational expenses)
    }
  }

  // ---------------------------------------------------------------------------
  // UI BUILDER
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceViewModel>(
      builder: (context, vm, _) {
        // 1. LOADING STATE
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        // 2. ERROR STATE
        if (vm.error != null) {
          return _buildErrorState(vm);
        }

        // 3. MAIN DASHBOARD CONTENT
        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,
          
          // Hidden AppBar to handle status bar area but defer control to Custom Header
          appBar: AppBar(
            backgroundColor: AppColors.backgroundBlack,
            elevation: 0,
            toolbarHeight: 0,
          ),

          body: RefreshIndicator(
            onRefresh: vm.refresh,
            color: AppColors.primaryBlue,
            backgroundColor: AppColors.surfaceDarkGrey,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Padding matches Dashboard layout (Top 20, Bottom 100 for Nav Bar clearance)
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  _buildHeader(vm),
                  const SizedBox(height: 24),

                  // HERO METRICS
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroCard(
                          title: "TOTAL REVENUE",
                          value: vm.totalRevenue,
                          subtitle: "${vm.percentGrowth >= 0 ? '+' : ''}${vm.percentGrowth.toStringAsFixed(1)}% Growth",
                          icon: Icons.arrow_downward,
                          color: AppColors.successGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildHeroCard(
                          title: "PENDING",
                          value: vm.pendingAmount,
                          subtitle: "${vm.unpaidInvoiceCount} Invoices",
                          icon: Icons.priority_high,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // QUICK ACTIONS
                  const Text(
                    "Quick Actions", 
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.add_circle_outline,
                          label: "Generate\nInvoice",
                          onTap: _navToCreateInvoice,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.payments_outlined,
                          label: "Record\nPayment",
                          onTap: _navToRecordPayment,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // COLLECTIONS TREND CHART
                  _buildTrendChart(vm.monthlyCollections, vm.monthLabels),

                  const SizedBox(height: 32),

                  // RECENT ACTIVITY FEED
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Activity", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      // TODO: Add "View All" button here when history screen is ready
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActivityList(vm.recentActivity),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SUB-WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildHeader(FinanceViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Finance",
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              "Overview",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: vm.refresh,
            tooltip: 'Refresh Data',
          ),
        )
      ],
    );
  }

  Widget _buildErrorState(FinanceViewModel vm) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
              const SizedBox(height: 16),
              Text(
                vm.error ?? "Unknown Error",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: vm.refresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Retry Connection"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required String title,
    required double value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title, 
                style: const TextStyle(
                  color: AppColors.textGrey, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 0.5
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "\$${value.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: color.withAlpha(200), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: AppColors.surfaceDarkGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<double> values, List<String> labels) {
    if (values.isEmpty) return const SizedBox.shrink();

    // Calculate dynamic height for bars
    final maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    final safeMax = maxVal > 0 ? maxVal : 1.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Collections Trend", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Last 6 Months", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(values.length, (index) {
                final val = values[index];
                final pct = (val / safeMax).clamp(0.0, 1.0);
                final label = labels.length > index ? labels[index] : "";

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Value Label (only for high values)
                    if (pct > 0.8) 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "\$${(val/1000).toStringAsFixed(1)}k",
                          style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    
                    // Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 24, 
                      // Min height of 10 to ensure visibility
                      height: 100 * pct + 10,
                      decoration: BoxDecoration(
                        color: pct > 0.8 ? AppColors.primaryBlue : AppColors.surfaceLightGrey.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Month Label
                    Text(
                      label,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActivityList(List<Map<String, dynamic>> rawActivities) {
    if (rawActivities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "No recent transactions.", 
            style: TextStyle(color: AppColors.textGrey)
          )
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rawActivities.length,
      itemBuilder: (context, index) {
        final item = _sanitizeActivity(rawActivities[index]);
        final isIncome = item['kind'] == _ActivityKind.income;
        
        return InkWell(
          onTap: () => _navToStudentIfPossible(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isIncome ? AppColors.successGreen.withAlpha(20) : AppColors.errorRed.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? AppColors.successGreen : AppColors.errorRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['desc'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Amount & Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isIncome ? '+' : '-'}\$${item['amount'].toStringAsFixed(2)}",
                      style: TextStyle(
                        color: isIncome ? AppColors.successGreen : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['time'],
                      style: TextStyle(color: AppColors.textGrey.withAlpha(150), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DATA SANITIZATION (UI Logic to parse dynamic data)
  // ---------------------------------------------------------------------------
  
  Map<String, dynamic> _sanitizeActivity(Map<String, dynamic> raw) {
    final name = (raw['name'] ?? 'Unknown').toString().trim();
    final desc = (raw['desc'] ?? raw['description'] ?? 'No description').toString().trim();
    final amountNum = raw['amount'];
    final amount = (amountNum is num) ? amountNum.toDouble() : 0.0;
    final time = (raw['time'] ?? '').toString().trim();
    final type = (raw['type'] ?? '').toString().toLowerCase().trim();
    
    // Attempt to resolve target ID from various common key names
    final targetId = raw['targetId'] ?? raw['studentId'] ?? raw['student_id'];

    // Determine transaction Kind (Income vs Expense)
    // "Payment" usually means money IN for schools. 
    // "Invoice" usually means we charged them (Pending) or Debited. 
    // Fallback: Positive amount is Income.
    final kind = (type.contains('payment'))
        ? _ActivityKind.income
        : (type.contains('invoice') || type.contains('debit') || type.contains('expense'))
            ? _ActivityKind.expense
            : (amount >= 0 ? _ActivityKind.income : _ActivityKind.expense);

    return {
      'name': name,
      'desc': desc,
      'amount': amount.abs(),
      'time': time.isEmpty ? '—' : time,
      'kind': kind,
      'targetId': targetId?.toString(),
    };
  }
}

enum _ActivityKind { income, expense }