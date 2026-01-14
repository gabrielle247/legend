import 'package:flutter/foundation.dart';
import 'package:legend/models/legend.dart';
import 'package:legend/repo/dashboard_repo.dart';
import 'package:legend/services/auth/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// SETTINGS VIEW MODEL
// =============================================================================
class SettingsViewModel extends ChangeNotifier {
  final AuthService _authService;
  final DashboardRepository _dashboardRepo;

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------
  bool isLoading = true;
  String? error;

  // User Preferences
  bool isDarkMode = true;
  bool pushNotifications = true;

  // User Profile
  LegendProfile? userProfile;
  String? schoolName;

  // Computed properties for null safety
  String? get userName => userProfile?.fullName;
  String? get userRole => userProfile?.role;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------------------------------
  SettingsViewModel(this._authService, this._dashboardRepo);

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    try {
      await _loadSettings();
      await _loadUserProfile();
      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint("Settings VM Init Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // SETTINGS MANAGEMENT
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // USER PROFILE
  // ---------------------------------------------------------------------------
  Future<void> _loadUserProfile() async {
    final user = _authService.user;
    final school = _authService.activeSchool;

    if (user != null) {
      try {
        userProfile = await _dashboardRepo.getUserProfile(user.id);
      } catch (e) {
        debugPrint("Error loading user profile: $e");
      }
    }

    if (school != null) {
      schoolName = school.name;
    }
  }

  // ---------------------------------------------------------------------------
  // AUTH ACTIONS
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    try {
      await _authService.logout();
      // Navigation will be handled by the screen
    } catch (e) {
      error = e.toString();
      debugPrint("Logout Error: $e");
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------
  Future<void> refresh() async {
    await init();
  }
}
