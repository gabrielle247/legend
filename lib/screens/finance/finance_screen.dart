import 'dart:core';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/vmodels/finance_vmodel.dart';
import 'package:provider/provider.dart';

// -----------------------------------------------------------------------------
// FINANCE SCREEN UI
// -----------------------------------------------------------------------------
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  //TODO Take all strings and putting them in AppStrings

  String _selectedTimeRange = 'Monthly';

  @override
  void initState() {
    super.initState();
    // Use the FinanceViewModel from Provider and initialize it when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().init();
    });
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION HANDLERS
  // ---------------------------------------------------------------------------
  void _navToTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction History module coming in next sprint'),
      ),
    );
  }

  void _navToStudent(String studentId) {
    context.push('${AppRoutes.students}/view/$studentId');
  }

  void _navToCreateInvoice() {
    context.push('${AppRoutes.finance}/${AppRoutes.createInvoice}');
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        if (vm.error != null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundBlack,
              title: const Text(
                'Finance Command',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vm.error!, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: vm.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,

          appBar: AppBar(
            backgroundColor: AppColors.backgroundBlack,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'Finance Command',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Filter options coming soon'),
                      backgroundColor: AppColors.surfaceLightGrey,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'REVENUE',
                        amount: '\$${vm.totalRevenue.toStringAsFixed(0)}',
                        subtitle: '+${vm.percentGrowth}% vs last month',
                        icon: Icons.attach_money,
                        color: AppColors.successGreen,
                        isPositive: true,
                        onTap: _navToTransactions,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'PENDING',
                        amount: '\$${vm.pendingAmount.toStringAsFixed(0)}',
                        subtitle: '! ${vm.unpaidInvoiceCount} Unpaid invoices',
                        icon: Icons.pending_actions_outlined,
                        color: Colors.orangeAccent,
                        isPositive: false,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Filtering Pending Invoices...'),
                              backgroundColor: AppColors.surfaceLightGrey,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildChartSection(vm),

                const SizedBox(height: 24),

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
                      onPressed: _navToTransactions,
                      child: const Text(
                        'View All',
                        style: TextStyle(color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),

                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: vm.recentActivity.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = vm.recentActivity[index];
                    return _buildActivityTile(
                      name: item['name'],
                      desc: item['desc'],
                      amount: item['amount'],
                      time: item['time'],
                      type: item['type'],
                      onTap: () => _navToStudent(item['targetId']),
                    );
                  },
                ),

                const SizedBox(height: 24),

                _buildInvoiceSection(),
              ],
            ),
          ),

          floatingActionButton: _buildFab(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildStatCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isPositive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textGrey.withAlpha(50),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isPositive ? AppColors.successGreen : Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(FinanceViewModel vm) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collections Trend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Academic Year 2026',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ],
              ),
              // Time Range Toggle
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildToggleButton('Weekly'),
                    _buildToggleButton('Monthly'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // DYNAMIC BAR CHART VISUALIZER
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              // Generating bars from the ViewModel's list
              children: List.generate(vm.monthlyCollections.length, (index) {
                return _buildBar(
                  heightPct: vm.monthlyCollections[index],
                  label: vm.monthLabels[index],
                  isActive:
                      index ==
                      3, // Mock active state logic (e.g., current month)
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text) {
    final isSelected = _selectedTimeRange == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeRange = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLightGrey : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textGrey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBar({
    required double heightPct,
    required String label,
    bool isActive = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // The Bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          width: 32,
          height: 110 * heightPct,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryBlue
                : AppColors.surfaceLightGrey.withAlpha(30),
            borderRadius: BorderRadius.circular(4),
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.primaryBlue, AppColors.primaryBlueLight],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        // The Label
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryBlue : AppColors.textGrey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile({
    required String name,
    required String desc,
    required double amount,
    required String time,
    required String type,
    required VoidCallback onTap,
  }) {
    final isWarning = type == 'WARNING';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isWarning
                  ? Colors.redAccent.withAlpha(20)
                  : AppColors.primaryBlue.withAlpha(20),
              child: Icon(
                isWarning ? Icons.priority_high : Icons.person,
                color: isWarning ? Colors.redAccent : AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isWarning
                      ? '\$${amount.toStringAsFixed(2)}'
                      : '+\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isWarning
                        ? Colors.redAccent
                        : AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Invoices',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Manage and track unpaid invoices',
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navToCreateInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Invoices'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _navToCreateInvoice,
      backgroundColor: AppColors.primaryBlue,
      elevation: 4,
      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      label: const Text(
        'Generate Invoice',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTransactionCard({
    required String name,
    required String description,
    required String amount,
    required String time,
    required bool isIncome,
    bool isWarning = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
        ),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              radius: 20,
              backgroundColor: isWarning
                  ? Colors.redAccent.withAlpha(20)
                  : AppColors.primaryBlue.withAlpha(20),
              child: Icon(
                isWarning ? Icons.priority_high : Icons.person,
                color: isWarning ? Colors.redAccent : AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Amount & Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    color: isWarning
                        ? Colors.redAccent
                        : (isIncome ? AppColors.successGreen : Colors.white),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
