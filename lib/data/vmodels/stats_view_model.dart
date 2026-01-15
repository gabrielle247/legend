import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/dashboard_repo.dart';
import 'package:legend/data/services/auth/auth.dart';

// -----------------------------------------------------------------------------
// 1. THE DATA CONTAINER (State Object)
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// 2. THE VIEW MODEL (Logic & State Management)
// -----------------------------------------------------------------------------
class StatsViewModel extends ChangeNotifier {
  final DashboardRepository _repo;
  final AuthService _authService;

  // State
  bool _isLoading = false;
  String? _error;
  StatsData _data = StatsData();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  StatsData get data => _data;

  StatsViewModel(this._repo, this._authService);

  /// Loads all analytics data from the local database
  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) {
        throw Exception("No active school found.");
      }

      // 1. Parallel Fetching for Performance
      final results = await Future.wait([
        _repo.getRevenueTrend(school.id),       // [0]
        _repo.getDebtByGrade(school.id),        // [1]
        _repo.getPaymentMethodStats(school.id), // [2]
        _repo.getDashboardStats(school.id),     // [3]
      ]);

      final revenueRows = results[0] as List<Map<String, dynamic>>;
      final debtByGrade = results[1] as List<Map<String, dynamic>>;
      final paymentMethods = results[2] as Map<String, double>;
      final dashboardStats = results[3] as DashboardStats;

      // 2. Process Revenue Trend (Convert SQL Rows -> Chart Spots)
      double calculatedRevenue = 0;
      List<FlSpot> spots = [];
      
      for (int i = 0; i < revenueRows.length; i++) {
        final row = revenueRows[i];
        final amount = (row['total'] as num).toDouble();
        calculatedRevenue += amount;
        // X: Day Index, Y: Amount in Thousands (k)
        spots.add(FlSpot(i.toDouble(), amount / 1000)); 
      }

      if (spots.isEmpty) spots.add(const FlSpot(0, 0));

      // 3. Update State
      _data = StatsData(
        totalRevenue: calculatedRevenue,
        outstandingDebt: dashboardStats.totalOwed,
        activeStudents: dashboardStats.totalStudents,
        revenueTrend: spots,
        debtByGrade: debtByGrade,
        paymentMethods: paymentMethods,
      );

    } catch (e) {
      _error = e.toString();
      debugPrint("StatsViewModel Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads data (e.g., for Pull-to-Refresh)
  Future<void> refresh() async {
    await loadStats();
  }
}