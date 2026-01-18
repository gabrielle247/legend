import 'package:fl_chart/fl_chart.dart';
import 'package:legend/app_libs.dart'; // Imports Auth, VModels, Constants

// -----------------------------------------------------------------------------
// UI IMPLEMENTATION
// -----------------------------------------------------------------------------
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Local UI State for Filters
  String _timeFilter = 'This Term';
  String _gradeFilter = 'All Grades';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsViewModel>().loadStats(
            timeFilter: _timeFilter,
            gradeFilter: _gradeFilter,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: _buildAppBar(context),
      body: Consumer<StatsViewModel>(
        builder: (context, vm, child) {
          // 1. LOADING
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
                strokeWidth: 2,
              ),
            );
          }

          // 2. ERROR
          if (vm.error != null) {
            return _buildErrorState(vm);
          }

          // 3. DATA READY
          final data = vm.data;
          final totalRevenue = data.totalRevenue;
          final totalOutstanding = data.outstandingDebt;
          final collectionRate = _collectionRate(totalRevenue, totalOutstanding);

          return RefreshIndicator(
            onRefresh: () => vm.loadStats(
              timeFilter: _timeFilter,
              gradeFilter: _gradeFilter,
            ),
            color: AppColors.primaryBlue,
            backgroundColor: AppColors.surfaceDarkGrey,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FILTERS ---
                  _buildFilterSection(context),
                  const SizedBox(height: 24),

                  // --- PRIMARY METRICS (HERO CARDS) ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroKpiCard(
                          title: "Total Revenue",
                          value: _formatAmount(totalRevenue),
                          subtitle: "Received",
                          icon: Icons.attach_money,
                          gradientColors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withAlpha(150),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeroKpiCard(
                          title: "Outstanding Debt",
                          value: _formatAmount(totalOutstanding),
                          subtitle: "Pending",
                          icon: Icons.warning_amber_rounded,
                          gradientColors: [
                            AppColors.errorRed.withAlpha(200),
                            AppColors.errorRed.withAlpha(100),
                          ],
                          isAlert: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // --- SECONDARY METRICS ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryKpiCard(
                          title: "Active Students",
                          value: data.activeStudents.toString(),
                          icon: Icons.people,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSecondaryKpiCard(
                          title: "Collection Rate",
                          value: "${(collectionRate * 100).toStringAsFixed(0)}%",
                          icon: Icons.pie_chart,
                          color: collectionRate >= 0.7
                              ? AppColors.successGreen
                              : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- REVENUE TRENDS ---
                  _buildSectionHeader("Revenue Trends", _timeFilter),
                  const SizedBox(height: 16),
                  _buildChartContainer(data.revenueTrend),

                  const SizedBox(height: 32),

                  // --- DEBT BY GRADE ---
                  _buildGradeFilterHeader(vm.availableGrades),
                  const SizedBox(height: 16),
                  _buildDebtList(data.debtByGrade),

                  const SizedBox(height: 32),

                  // --- PAYMENT CHANNELS ---
                  _buildSectionHeader("Payment Channels", ""),
                  const SizedBox(height: 16),
                  _buildPaymentChannels(data.paymentMethods),

                  const SizedBox(height: 48), // Bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUB-WIDGETS & BUILDERS
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundBlack,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
        ),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Analytics',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined, color: AppColors.textGrey, size: 20),
          onPressed: () {
            // Future feature: Date picker
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(StatsViewModel vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: AppColors.surfaceLightGrey.withAlpha(100), size: 64),
          const SizedBox(height: 16),
          Text(
            "Could not load analytics",
            style: TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: vm.refresh,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
            ),
            child: const Text("Tap to Retry"),
          )
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('This Term', _timeFilter, (val) => _applyFilters(context, val, _gradeFilter)),
          const SizedBox(width: 8),
          _buildFilterChip('Last Term', _timeFilter, (val) => _applyFilters(context, val, _gradeFilter)),
          const SizedBox(width: 8),
          _buildFilterChip('All Time', _timeFilter, (val) => _applyFilters(context, val, _gradeFilter)),
        ],
      ),
    );
  }

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
          border: isSelected
              ? null
              : Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withAlpha(200), size: 20),
              if (isAlert)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildChartContainer(List<FlSpot> spots) {
    if (spots.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("No chart data available", style: TextStyle(color: AppColors.textGrey)),
      );
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1000, 
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.surfaceLightGrey.withAlpha(10),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: const FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1, // Simplified for visual clarity
                // In a real app, you'd map indexes to dates here
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primaryBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withAlpha(80),
                    AppColors.primaryBlue.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeFilterHeader(List<String> grades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Debt by Grade", ""),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Grades', _gradeFilter, (val) => _applyFilters(context, _timeFilter, val)),
              ...grades.map((grade) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildFilterChip(grade, _gradeFilter, (val) => _applyFilters(context, _timeFilter, val)),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebtList(List<Map<String, dynamic>> debtData) {
    if (debtData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
        ),
        child: const Text("No outstanding debt records.", style: TextStyle(color: AppColors.textGrey)),
      );
    }

    double maxVal = 0;
    for (var i in debtData) {
      final v = (i['amount'] as num).toDouble();
      if (v > maxVal) maxVal = v;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Column(
        children: debtData.map((item) {
          final amt = (item['amount'] as num).toDouble();
          final pct = maxVal > 0 ? (amt / maxVal) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    item['grade'] ?? '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: pct > 0.6 ? AppColors.errorRed : AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 70,
                  child: Text(
                    _formatAmount(amt),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: pct > 0.6 ? AppColors.errorRed : AppColors.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentChannels(Map<String, double> channels) {
    if (channels.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text("No channel data.", style: TextStyle(color: AppColors.textGrey))),
      );
    }

    final total = channels.values.fold(0.0, (p, c) => p + c);
    final entries = channels.entries.toList();
    // Sort by value descending for better pie chart visual
    entries.sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      AppColors.primaryBlue,
      Colors.cyanAccent,
      Colors.purpleAccent,
      AppColors.errorRed,
      Colors.orange,
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 30,
                sections: entries.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return PieChartSectionData(
                    color: colors[idx % colors.length],
                    value: item.value,
                    radius: 20,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;
                final percentage = total > 0 ? (item.value / total) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors[idx % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.key,
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "${(percentage * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGIC HELPERS
  // ---------------------------------------------------------------------------

  void _applyFilters(BuildContext context, String time, String grade) {
    setState(() {
      _timeFilter = time;
      _gradeFilter = grade;
    });
    // Fire & Forget - VM handles loading state
    context.read<StatsViewModel>().loadStats(
          timeFilter: _timeFilter,
          gradeFilter: _gradeFilter,
        );
  }

  double _collectionRate(double revenue, double outstanding) {
    final total = revenue + outstanding;
    if (total <= 0) return 0.0;
    return (revenue / total).clamp(0.0, 1.0);
  }

  String _formatAmount(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return "\$${(value / 1000000).toStringAsFixed(1)}M";
    if (abs >= 1000) return "\$${(value / 1000).toStringAsFixed(1)}K";
    return "\$${value.toStringAsFixed(0)}";
  }
}