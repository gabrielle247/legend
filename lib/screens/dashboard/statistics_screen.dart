import 'package:fl_chart/fl_chart.dart';
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
class StatsViewModel {
  final double totalRevenue;
  final double outstandingDebt;
  final int activeStudents;

  // Chart Data
  final List<FlSpot> revenueTrend;
  final List<Map<String, dynamic>> debtByGrade;
  final Map<String, double> paymentMethods;

  StatsViewModel({
    required this.totalRevenue,
    required this.outstandingDebt,
    required this.activeStudents,
    required this.revenueTrend,
    required this.debtByGrade,
    required this.paymentMethods,
  });

  // Empty state to avoid null crashes if DB is empty
  factory StatsViewModel.empty() {
    return StatsViewModel(
      totalRevenue: 0,
      outstandingDebt: 0,
      activeStudents: 0,
      revenueTrend: [const FlSpot(0, 0)],
      debtByGrade: [],
      paymentMethods: {},
    );
  }
}

// -----------------------------------------------------------------------------
// UI IMPLEMENTATION
// -----------------------------------------------------------------------------
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Filters State
  String _timeFilter = 'This Term';
  String _gradeFilter = 'All Grades';

  // Async State
  late Future<StatsViewModel> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  /// --------------------------------------------------------------------------
  /// DATA LOADER (Real DB Fetching)
  /// --------------------------------------------------------------------------
  Future<StatsViewModel> _loadData() async {
    final authService = context.read<AuthService>();
    final dashboardRepo = context.read<DashboardRepository>();
    
    final school = authService.activeSchool;
    if (school == null) return StatsViewModel.empty();

    try {
      // 1. Fetch all required data in parallel
      final results = await Future.wait([
        dashboardRepo.getRevenueTrend(school.id),      // index 0
        dashboardRepo.getDebtByGrade(school.id),       // index 1
        dashboardRepo.getPaymentMethodStats(school.id),// index 2
        dashboardRepo.getDashboardStats(school.id),    // index 3
      ]);

      final revenueTrendRows = results[0] as List<Map<String, dynamic>>;
      final debtByGrade = results[1] as List<Map<String, dynamic>>;
      final paymentMethods = results[2] as Map<String, double>;
      final dashboardStats = results[3] as DashboardStats;

      // 2. Process Revenue Trend (SQL Date -> FlSpot)
      double calculatedRevenue = 0;
      List<FlSpot> spots = [];
      
      for (int i = 0; i < revenueTrendRows.length; i++) {
        final row = revenueTrendRows[i];
        final amount = (row['total'] as num).toDouble();
        calculatedRevenue += amount;
        // X-Axis = Index (Day 0, Day 1...), Y-Axis = Amount in Thousands (k)
        spots.add(FlSpot(i.toDouble(), amount / 1000)); 
      }

      return StatsViewModel(
        totalRevenue: calculatedRevenue,
        outstandingDebt: dashboardStats.totalOwed, // Source of Truth from Repo
        activeStudents: dashboardStats.totalStudents,
        revenueTrend: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
        debtByGrade: debtByGrade,
        paymentMethods: paymentMethods,
      );

    } catch (e) {
      debugPrint("Stats Load Error: $e");
      return StatsViewModel.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,

      // HEADER
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.primaryBlue),
            tooltip: "Export Report",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting PDF...'), backgroundColor: AppColors.surfaceLightGrey),
              );
            },
          ),
        ],
      ),

      // BODY
      body: FutureBuilder<StatsViewModel>(
        future: _dataFuture,
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }

          // 2. Error
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: AppColors.errorRed)));
          }

          // 3. Data Ready
          final _data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. FILTER BAR
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('This Term', _timeFilter, (val) => setState(() => _timeFilter = val)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Last Term', _timeFilter, (val) => setState(() => _timeFilter = val)),
                      const SizedBox(width: 8),
                      _buildFilterChip('All Grades', _gradeFilter, (val) => setState(() => _gradeFilter = val)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. KPI CARDS
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: "Revenue (7 Days)",
                        value: "\$${(_data.totalRevenue).toStringAsFixed(0)}",
                        // Trend is removed because we need previous period data to calculate it truthfully
                        trend: "Real-time", 
                        isPositive: true,
                        icon: Icons.show_chart,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKpiCard(
                        title: "Total Outstanding",
                        value: "\$${(_data.outstandingDebt / 1000).toStringAsFixed(1)}k",
                        trend: "Unpaid Fees",
                        isPositive: false,
                        icon: Icons.warning_amber,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 3. REVENUE TREND
                const Text(
                  "Income Trajectory",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Daily collections (in thousands)",
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: const EdgeInsets.only(right: 16, top: 24, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _data.revenueTrend,
                          isCurved: true,
                          color: AppColors.primaryBlue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primaryBlue.withAlpha(30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 4. DEBT BY GRADE
                const Text(
                  "Debt Distribution",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: _data.debtByGrade.isEmpty 
                    ? [const Padding(padding: EdgeInsets.all(8.0), child: Text("No debt records found.", style: TextStyle(color: AppColors.textGrey)))]
                    : _data.debtByGrade.map((item) {
                        // Dynamic Max for Scaling Bars correctly
                        // Find max debt in the list to normalize the bar width
                        final double maxDebtInList = _data.debtByGrade.fold(0.0, (prev, e) {
                          final amt = (e['amount'] as num).toDouble();
                          return amt > prev ? amt : prev;
                        });
                        
                        final double amount = (item['amount'] as num).toDouble();
                        final double pct = maxDebtInList > 0 ? (amount / maxDebtInList).clamp(0.0, 1.0) : 0.0;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  item['grade'] ?? 'N/A',
                                  style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLightGrey.withAlpha(50),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: pct,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: pct > 0.7 ? AppColors.errorRed : Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  "\$${amount.toStringAsFixed(0)}",
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildFilterChip(String label, String currentSelection, Function(String) onSelect) {
    final bool isSelected = label == currentSelection;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.surfaceLightGrey.withAlpha(50),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textGrey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
    Color? color,
  }) {
    final themeColor = color ?? AppColors.primaryBlue;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: themeColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.successGreen.withAlpha(20) : AppColors.errorRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: isPositive ? AppColors.successGreen : AppColors.errorRed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}