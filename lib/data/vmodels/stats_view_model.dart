import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/dashboard_repo.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/services/auth/auth.dart';

class StatsData {
  final double totalRevenue;
  final double outstandingDebt;
  final int activeStudents;
  final List<FlSpot> revenueTrend;
  final List<Map<String, dynamic>> debtByGrade;
  final Map<String, double> paymentMethods;

  StatsData({
    this.totalRevenue = 0,
    this.outstandingDebt = 0,
    this.activeStudents = 0,
    this.revenueTrend = const [FlSpot(0, 0)],
    this.debtByGrade = const [],
    this.paymentMethods = const {},
  });
}

class StatsViewModel extends ChangeNotifier {
  final DashboardRepository _dashboardRepo;
  final FinanceRepository _financeRepo;
  final AuthService _authService;

  bool _isLoading = false;
  String? _error;
  StatsData _data = StatsData();

  bool get isLoading => _isLoading;
  String? get error => _error;
  StatsData get data => _data;

  StatsViewModel(this._dashboardRepo, this._financeRepo, this._authService);

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) throw Exception("No active school found.");

      // Single source of truth:
      // - totals come from finance stats
      // - charts come from dashboard repo trend queries
      final results = await Future.wait([
        _dashboardRepo.getRevenueTrend(school.id),
        _dashboardRepo.getDebtByGrade(school.id),
        _dashboardRepo.getPaymentMethodStats(school.id),
        _dashboardRepo.getDashboardStats(school.id),
        _financeRepo.getFinanceStats(school.id),
      ]);

      final revenueRows = results[0] as List<Map<String, dynamic>>;
      final debtByGrade = results[1] as List<Map<String, dynamic>>;
      final paymentMethods = results[2] as Map<String, double>;
      final dashboardStats = results[3] as DashboardStats;
      final financeStats = results[4] as Map<String, dynamic>;

      // Chart spots (7 days trend)
      final List<FlSpot> spots = [];
      for (int i = 0; i < revenueRows.length; i++) {
        final row = revenueRows[i];
        final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
        spots.add(FlSpot(i.toDouble(), amount / 1000.0));
      }
      if (spots.isEmpty) spots.add(const FlSpot(0, 0));

      _data = StatsData(
        totalRevenue: (financeStats['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        outstandingDebt: dashboardStats.totalOwed,
        activeStudents: dashboardStats.totalStudents,
        revenueTrend: spots,
        debtByGrade: debtByGrade,
        paymentMethods: paymentMethods,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint("StatsViewModel.loadStats error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadStats();
}
