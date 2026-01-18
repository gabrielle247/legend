import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/dashboard_repo.dart';
import 'package:legend/data/services/noti/notification_engine.dart';
import 'package:legend/data/services/auth/auth.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repo;
  final AuthService _authService;
  StreamSubscription<DashboardStats>? _statsSub;

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
  Stream<List<LegendNotification>>? notificationsStream;
  Stream<int>? unreadCountStream;
  String? _schoolId;

  DashboardViewModel(this._repo, this._authService);

  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final user = _authService.user;
      final school = _authService.activeSchool;
      if (user == null || school == null) throw Exception("Session invalid.");
      _schoolId = school.id;

      _startStatsWatch(school.id);
      _startNotificationsWatch(school.id);

      await Future.wait([
        _loadProfile(user.id),
        _loadStats(school.id),
        _loadActivity(school.id),
      ]);

      unawaited(_runNotificationChecks(school.id, user.id));
    } catch (e) {
      error = e.toString();
      debugPrint("DashboardViewModel.init error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(String userId) async {
    profile = await _repo.getUserProfile(userId);
  }

  Future<void> _loadStats(String schoolId) async {
    stats = await _repo.getDashboardStats(schoolId);
  }

  Future<void> _loadActivity(String schoolId) async {
    recentActivity = await _repo.getRecentActivity(schoolId);
  }

  Future<void> refresh() => init();

  void _startStatsWatch(String schoolId) {
    _statsSub?.cancel();
    _statsSub = _repo.watchDashboardStats(schoolId).listen(
      (next) {
        stats = next;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void _startNotificationsWatch(String schoolId) {
    notificationsStream = _repo.watchNotifications(schoolId);
    unreadCountStream = _repo.watchUnreadCount(schoolId);
    notifyListeners();
  }

  Future<void> _runNotificationChecks(String schoolId, String userId) async {
    try {
      await NotificationEngine().runChecks(schoolId, userId);
    } catch (e) {
      debugPrint("NotificationEngine.runChecks error: $e");
    }
  }

  Future<void> markNotificationRead(String notiId) => _repo.markAsRead(notiId);
  Future<void> markAllNotificationsRead() async {
    final schoolId = _schoolId;
    if (schoolId == null) return;
    await _repo.markAllAsRead(schoolId);
  }

  Future<void> clearAllNotifications() async {
    final schoolId = _schoolId;
    if (schoolId == null) return;
    await _repo.clearAllNotifications(schoolId);
  }

  Future<void> deleteNotification(String id) => _repo.deleteNotification(id);

  @override
  void dispose() {
    _statsSub?.cancel();
    super.dispose();
  }
}
