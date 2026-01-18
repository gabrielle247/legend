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
  // UI State for "Placebo" Filters
  int _selectedTimeRangeIndex = 2; // Default to 'Month'
  int _selectedTxTypeIndex = 0; // Default to 'All'
  final List<String> _timeRanges = ["Today", "Week", "Month", "Year"];
  final List<String> _txFilters = ["All", "Income", "Pending", "Expenses"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().init();
    });
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION HANDLERS
  // ---------------------------------------------------------------------------
  void _navToCreateInvoice() => context.push('${AppRoutes.finance}/${AppRoutes.createInvoice}');
  void _navToRecordPayment() => context.push('${AppRoutes.finance}/${AppRoutes.recordPayment}');
  void _navToDashboardOutstanding() => context.go('${AppRoutes.dashboard}/${AppRoutes.outstanding}');
  void _navToDashboardReceived() => context.go('${AppRoutes.dashboard}/${AppRoutes.received}');
  void _navToDashboardActivity() => context.go('${AppRoutes.dashboard}/${AppRoutes.activity}');
  
  void _navToStudentIfPossible(Map<String, dynamic> item) {
    final targetId = item['targetId']?.toString();
    if (targetId != null && targetId.isNotEmpty) {
      context.push('${AppRoutes.students}/view/$targetId');
    }
  }

  // ---------------------------------------------------------------------------
  // UI BUILDER
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
          );
        }

        if (vm.error != null) {
          return _buildErrorState(vm);
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,
          // Hide default AppBar
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
              padding: const EdgeInsets.only(bottom: 100), // Nav clearance
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP CONTROL BAR (Header + Time Filters)
                  _buildTopControlBar(vm),
                  
                  const SizedBox(height: 20),

                  // 2. MASTER CARD (The "Central" Dashboard feel)
                  _buildMasterFinancialCard(vm),

                  const SizedBox(height: 24),

                  // 3. ACTION COMMAND CENTER (Replacing demotivating buttons)
                  _buildActionCommandCenter(),

                  const SizedBox(height: 32),

                  // 4. ANALYTICS SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cash Flow Trend",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildTrendChart(vm.monthlyCollections, vm.monthLabels),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 5. OUTSTANDING BALANCES
                  _buildOutstandingSection(vm.outstandingStudents),

                  const SizedBox(height: 32),

                  // 6. LATEST PAYMENTS
                  _buildRecentPaymentsSection(vm.recentPayments),

                  const SizedBox(height: 32),

                  // 7. SMART ACTIVITY FEED
                  _buildSmartActivitySection(vm.recentActivity),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP CONTROL BAR
  // ---------------------------------------------------------------------------
  Widget _buildTopControlBar(FinanceViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Overview",
                    style: TextStyle(
                      color: AppColors.textGrey.withAlpha(150),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Financial Health",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: vm.refresh,
                icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Time Range Filter (Placebo UI)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _timeRanges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedTimeRangeIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTimeRangeIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlue : AppColors.surfaceDarkGrey,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected 
                        ? null 
                        : Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                    ),
                    child: Text(
                      _timeRanges[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. MASTER FINANCIAL CARD
  // ---------------------------------------------------------------------------
  Widget _buildMasterFinancialCard(FinanceViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        // Subtle gradient effect using the theme blue
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceDarkGrey,
            AppColors.backgroundBlack,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decor (Abstract Circle)
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withAlpha(15),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward, color: AppColors.successGreen, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "${vm.percentGrowth}%",
                            style: const TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_horiz, color: AppColors.textGrey),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Total Collections",
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${vm.totalRevenue.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 24),
                // Footer Stats (Pending)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high, color: Colors.orangeAccent, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "\$${vm.pendingAmount.toStringAsFixed(0)} Pending",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            "${vm.unpaidInvoiceCount} unpaid invoices",
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ACTION COMMAND CENTER
  // ---------------------------------------------------------------------------
  Widget _buildActionCommandCenter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Primary Action (Solid Blue)
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _navToCreateInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text("New Invoice", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Secondary Action (Dark Surface)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _navToRecordPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceDarkGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(20)),
                ),
                elevation: 0,
              ),
              child: const Text("Record Pay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. CHART (Cleaner Layout)
  // ---------------------------------------------------------------------------
  Widget _buildTrendChart(List<double> values, List<String> labels) {
    if (values.isEmpty) return const SizedBox.shrink();
    
    final maxVal = values.fold(0.0, (p, c) => p > c ? p : c);
    final safeMax = maxVal > 0 ? maxVal : 1.0;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(values.length, (index) {
          final val = values[index];
          final pct = (val / safeMax).clamp(0.0, 1.0);
          final label = labels.length > index ? labels[index] : "";
          final isPeak = pct > 0.9;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isPeak)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.star, color: AppColors.primaryBlue.withAlpha(150), size: 10),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                width: 32,
                height: 100 * pct + 10,
                decoration: BoxDecoration(
                  color: isPeak ? AppColors.primaryBlue : AppColors.surfaceLightGrey.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isPeak ? Colors.white : AppColors.textGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. SMART ACTIVITY SECTION
  // ---------------------------------------------------------------------------
  Widget _buildSmartActivitySection(List<Map<String, dynamic>> rawActivities) {
    return Column(
      children: [
        // Section Header with Filter Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transactions",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _navToDashboardActivity,
                    child: const Text("View All", style: TextStyle(color: AppColors.primaryBlue, fontSize: 12)),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: List.generate(_txFilters.length, (index) {
                      final isSelected = _selectedTxTypeIndex == index;
                      if (index > 2) return const SizedBox.shrink(); // Limit to first 3 for space
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTxTypeIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceLightGrey.withAlpha(50) : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _txFilters[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // The List
        if (rawActivities.isEmpty) 
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("No data available", style: TextStyle(color: AppColors.textGrey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: rawActivities.length,
            itemBuilder: (context, index) {
              final item = _sanitizeActivity(rawActivities[index]);
              final isIncome = item['kind'] == _ActivityKind.income;
              
              // Placebo Filtering Logic (Visual only)
              if (_selectedTxTypeIndex == 1 && !isIncome) return const SizedBox.shrink(); // Show Income Only
              if (_selectedTxTypeIndex == 2 && isIncome) return const SizedBox.shrink(); // Show Expense/Pending Only

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _navToStudentIfPossible(item),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDarkGrey,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                        ),
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? AppColors.successGreen : Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${isIncome ? '+' : '-'}\$${item['amount'].toStringAsFixed(0)}",
                            style: TextStyle(
                              color: isIncome ? AppColors.successGreen : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['time'],
                            style: TextStyle(color: AppColors.textGrey.withAlpha(100), fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS (Error State & Logic)
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(FinanceViewModel vm) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(vm.error!, style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: vm.refresh,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _sanitizeActivity(Map<String, dynamic> raw) {
    final name = (raw['name'] ?? 'Unknown').toString().trim();
    final desc = (raw['desc'] ?? raw['description'] ?? 'No description').toString().trim();
    final amountNum = raw['amount'];
    final amount = (amountNum is num) ? amountNum.toDouble() : 0.0;
    final time = (raw['time'] ?? '').toString().trim();
    final type = (raw['type'] ?? '').toString().toLowerCase().trim();
    final targetId = raw['targetId'] ?? raw['studentId'] ?? raw['student_id'];

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

  // ---------------------------------------------------------------------------
  // 6. OUTSTANDING SECTION
  // ---------------------------------------------------------------------------
  Widget _buildOutstandingSection(List<Map<String, dynamic>> rows) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Outstanding Balances",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _navToDashboardOutstanding,
                child: const Text("View All", style: TextStyle(color: AppColors.primaryBlue, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text("No outstanding balances.", style: TextStyle(color: AppColors.textGrey)),
            )
          else
            Column(
              children: rows.map((row) {
                final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
                final name = (row['name'] ?? 'Unknown').toString();
                final grade = (row['grade'] ?? '—').toString();
                final studentId = (row['id'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.errorRed.withAlpha(20),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Grade $grade", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "\$${amount.toStringAsFixed(0)}",
                            style: const TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: studentId.isEmpty
                                ? null
                                : () => context.push(
                                      '${AppRoutes.finance}/${AppRoutes.recordPayment}?studentId=$studentId',
                                    ),
                            child: const Text("Log Payment", style: TextStyle(color: AppColors.primaryBlue, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. RECENT PAYMENTS
  // ---------------------------------------------------------------------------
  Widget _buildRecentPaymentsSection(List<Map<String, dynamic>> rows) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Latest Payments",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _navToDashboardReceived,
                child: const Text("View All", style: TextStyle(color: AppColors.primaryBlue, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text("No recent payments.", style: TextStyle(color: AppColors.textGrey)),
            )
          else
            Column(
              children: rows.map((row) {
                final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
                final name = (row['name'] ?? 'Unknown').toString();
                final method = (row['method'] ?? '—').toString();
                final time = (row['time'] ?? '—').toString();
                final studentId = (row['studentId'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                  ),
                  child: InkWell(
                    onTap: studentId.isEmpty ? null : () => context.push('${AppRoutes.students}/view/$studentId'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.successGreen.withAlpha(20),
                          child: const Icon(Icons.arrow_downward, color: AppColors.successGreen, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(method, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "+\$${amount.toStringAsFixed(0)}",
                              style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(time, style: TextStyle(color: AppColors.textGrey.withAlpha(120), fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

enum _ActivityKind { income, expense }
