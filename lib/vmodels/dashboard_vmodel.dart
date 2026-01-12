import 'package:flutter/foundation.dart';
import 'package:legend/models/legend.dart';
import 'package:legend/repo/dashboard_repo.dart';
import 'package:legend/services/auth/auth_serv.dart';
import 'package:legend/services/database_serv.dart'; // To init DB

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repo;
  final AuthService _authService;

  // ---------------------------------------------------------------------------
  // STATE (Data the UI needs)
  // ---------------------------------------------------------------------------
  bool isLoading = true;
  String? error;

  LegendProfile? profile;
  DashboardStats stats = DashboardStats(
    totalStudents: 0,
    totalOwed: 0,
    collectedToday: 0,
    pendingInvoices: 0,
  );
  List<Map<String, dynamic>> recentActivity = [];

  // Constructor Injection
  DashboardViewModel(this._repo, this._authService);

  // ---------------------------------------------------------------------------
  // INITIALIZATION (The Engine Start)
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    isLoading = true;
    notifyListeners(); // Tell UI to show spinner

    try {
      // 1. Get Current Context (User & School)
      final user = _authService.user;
      final school = _authService.activeSchool;

      if (user == null || school == null) {
        throw Exception("Session invalid. Please login again.");
      }

      // 2. Ignite the Offline Database (If not already running)
      // PowerSync is already connected in AuthService.login()
      await DatabaseService().connectToSchool(school.id);

      // 3. Parallel Data Fetching (Maximum Efficiency)
      // We run all independent queries at the same time.
      await Future.wait([
        _loadProfile(user.id),
        _loadStats(school.id),
        _loadActivity(school.id),
      ]);

      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint("Dashboard VM Error: $e");
    } finally {
      isLoading = false;
      notifyListeners(); // Tell UI we are ready
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER METHODS (Clean Logic)
  // ---------------------------------------------------------------------------

  Future<void> _loadProfile(String userId) async {
    profile = await _repo.getUserProfile(userId);
  }

  Future<void> _loadStats(String schoolId) async {
    stats = await _repo.getDashboardStats(schoolId);
  }

  Future<void> _loadActivity(String schoolId) async {
    recentActivity = await _repo.getRecentActivity(schoolId);
  }

  // ---------------------------------------------------------------------------
  // ACTIONS (User Interactions)
  // ---------------------------------------------------------------------------

  Future<void> refresh() async {
    await init();
  }

  // Called when user logs out to prevent memory leaks or open connections
  Future<void> disconnect() async {
    // FIXED: Use close() instead of disconnect() to match database service API
    await DatabaseService().close();
  }
}
