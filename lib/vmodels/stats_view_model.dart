import 'package:fl_chart/fl_chart.dart';

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
