import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/dashboard_repo.dart';
import 'package:legend/data/services/auth/auth.dart';
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

  String? get userName => userProfile?.fullName;
  String? get userRole => userProfile?.role;

  SettingsViewModel(this._authService, this._dashboardRepo);

  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _loadSettings();
      await _loadContext();
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
}
