import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/dashboard_repo.dart';
import 'package:legend/data/services/auth/auth.dart';
import 'package:legend/data/services/billing/billing_engine.dart';
import 'package:legend/data/services/database_serv.dart';
import 'package:legend/data/constants/app_strings.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthService _authService;
  final DashboardRepository _dashboardRepo;

  bool isLoading = true;
  String? error;

  bool isDarkMode = true;
  bool pushNotifications = true;

  LegendProfile? userProfile;
  String? schoolName;

  SyncStatus? _syncStatus;
  String _syncStatusLabel = AppStrings.subSyncUnknown;
  StreamSubscription<SyncStatus>? _syncSub;
  bool _autoBillingEnabled = false;
  String? _autoBillingError;
  bool _autoBillingLocked = false;
  bool _isDeletingData = false;

  String? get userName => userProfile?.fullName;
  String? get userRole => userProfile?.role;
  String get syncStatusLabel => _syncStatusLabel;
  SyncStatus? get syncStatus => _syncStatus;
  bool get autoBillingEnabled => _autoBillingEnabled;
  String? get autoBillingError => _autoBillingError;
  bool get autoBillingLocked => _autoBillingLocked;
  bool get isDeletingData => _isDeletingData;

  SettingsViewModel(this._authService, this._dashboardRepo);

  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _loadSettings();
      await _loadContext();
      _startSyncWatch();
      await _loadAutoBilling();
    } catch (e) {
      error = e.toString();
      debugPrint("SettingsViewModel.init error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? true;
    pushNotifications = prefs.getBool('pushNotifications') ?? true;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setBool('pushNotifications', pushNotifications);
  }

  Future<void> toggleDarkMode() async {
    isDarkMode = !isDarkMode;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> togglePushNotifications() async {
    pushNotifications = !pushNotifications;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _loadContext() async {
    final user = _authService.user;
    final school = _authService.activeSchool;

    schoolName = school?.name;

    if (user == null) {
      userProfile = null;
      return;
    }

    // If profile is missing, keep it null but do not lie to UI.
    userProfile = await _dashboardRepo.getUserProfile(user.id);
  }

  Future<void> _loadAutoBilling() async {
    final schoolId = _authService.activeSchool?.id;
    if (schoolId == null) return;
    _autoBillingEnabled = await BillingEngine().isAutoBillingEnabled(schoolId);
  }

  void _startSyncWatch() {
    _syncSub?.cancel();

    final current = DatabaseService().currentStatus;
    if (current != null) {
      _syncStatus = current;
      _syncStatusLabel = _formatSyncStatus(current);
      notifyListeners();
    }

    _syncSub = DatabaseService().statusStream.listen(
      (status) {
        _syncStatus = status;
        _syncStatusLabel = _formatSyncStatus(status);
        notifyListeners();
      },
      onError: (e) {
        _syncStatusLabel = "Sync error";
        notifyListeners();
      },
    );
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      error = e.toString();
      debugPrint("SettingsViewModel.logout error: $e");
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refresh() => init();

  String _formatSyncStatus(SyncStatus status) {
    if (status.anyError != null) return AppStrings.syncError;
    if (status.connecting) return AppStrings.syncConnecting;
    if (status.downloading || status.uploading) return AppStrings.syncSyncing;
    if (status.connected) {
      final last = status.lastSyncedAt;
      if (last != null) return "${AppStrings.syncLastSyncedPrefix}${_formatSyncTime(last)}";
      return AppStrings.syncConnected;
    }
    return status.hasSynced == true ? AppStrings.syncOfflineCached : AppStrings.syncOffline;
  }

  String _formatSyncTime(DateTime time) {
    final local = time.toLocal();
    final date = local.toIso8601String().split('T').first;
    final clock = local.toIso8601String().split('T').last.substring(0, 5);
    return "$date $clock";
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> toggleAutoBilling(bool enabled) async {
    _autoBillingError = null;
    _autoBillingLocked = false;
    final schoolId = _authService.activeSchool?.id;
    if (schoolId == null) return;

    if (enabled) {
      final ok = await BillingEngine().enableAutoBilling(schoolId);
      if (!ok) {
        _autoBillingError = AppStrings.autoBillingLockHeld;
        _autoBillingLocked = true;
        _autoBillingEnabled = false;
        notifyListeners();
        return;
      }
      _autoBillingEnabled = true;
      await BillingEngine().runDaily(schoolId);
    } else {
      await BillingEngine().disableAutoBilling(schoolId);
      _autoBillingEnabled = false;
    }

    notifyListeners();
  }

  Future<void> takeOverAutoBilling() async {
    _autoBillingError = null;
    _autoBillingLocked = false;
    final schoolId = _authService.activeSchool?.id;
    if (schoolId == null) return;

    await BillingEngine().takeOverAutoBilling(schoolId);
    _autoBillingEnabled = true;
    await BillingEngine().runDaily(schoolId);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> loadAutoBillingErrors() async {
    final schoolId = _authService.activeSchool?.id;
    if (schoolId == null) return [];
    return BillingEngine().getErrorLog(schoolId);
  }

  Future<void> clearAutoBillingErrors() async {
    final schoolId = _authService.activeSchool?.id;
    if (schoolId == null) return;
    await BillingEngine().clearErrorLog(schoolId);
  }

  Future<void> deleteAllStudentData() async {
    final schoolId = _authService.activeSchool?.id;
    if (schoolId == null) {
      throw Exception(AppStrings.noActiveSchool);
    }

    _isDeletingData = true;
    notifyListeners();

    try {
      await _dashboardRepo.deleteAllStudentData(schoolId);
    } finally {
      _isDeletingData = false;
      notifyListeners();
    }
  }
}
