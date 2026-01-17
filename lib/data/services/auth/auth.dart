import 'package:flutter/foundation.dart';
import 'package:legend/data/models/school_config.dart';
import 'package:legend/data/repo/auth/auth.dart';
import 'package:legend/data/repo/auth/school_repo.dart';
import 'package:legend/data/services/database_serv.dart';
import 'package:legend/data/services/powersync/supa_connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final AuthRepository _authRepo;
  final SchoolRepository _schoolRepo;

  // STATE
  SchoolConfig? _activeSchool;
  bool _isLoading = true;
  bool _requiresOnlineSetup = false;

  // GETTERS
  User? get user => _authRepo.currentUser;
  SchoolConfig? get activeSchool => _activeSchool;
  bool get isLoading => _isLoading;
  bool get requiresOnlineSetup => _requiresOnlineSetup;
  bool get isAuthenticated => _authRepo.currentUser != null;

  AuthService(this._authRepo, this._schoolRepo) {
    _restoreSession();
  }

  // ---------------------------------------------------------------------------
  // 1) SESSION RESTORATION (OFFLINE-FIRST)
  // ---------------------------------------------------------------------------
  Future<void> _restoreSession() async {
    final userId = _authRepo.currentUser?.id;

    if (userId == null) {
      _isLoading = false;
      _requiresOnlineSetup = false;
      _activeSchool = null;
      notifyListeners();
      return;
    }

    debugPrint("🔄 Restoring session for: $userId");

    try {
      // A) Try local cache FIRST (must be user-scoped)
      _activeSchool = await _schoolRepo.getLocalSchool(userId);

      if (_activeSchool != null) {
        debugPrint("✅ Offline Session Restored: ${_activeSchool!.name}");
        _requiresOnlineSetup = false;

        // Ignite PowerSync immediately with cached config
        await _connectPowerSync();

        // Optional background refresh (does not block UI)
        _backgroundRefresh(userId);
      } else {
        // B) No cache -> MUST go online once
        debugPrint("⚠️ No local school found. Attempting online fetch...");
        await _fetchSchoolOnline(userId);
      }
    } catch (e) {
      debugPrint("❌ Session Restoration Failed: $e");

      // If we have a user session but no school config, we cannot proceed offline.
      if (_activeSchool == null) {
        _requiresOnlineSetup = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 2) HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _fetchSchoolOnline(String userId) async {
    // If offline or blocked by RLS, this throws and caller handles it
    _activeSchool = await _schoolRepo.getSchoolForUser(userId);
    _requiresOnlineSetup = false;
    await _connectPowerSync();
  }

  Future<void> _backgroundRefresh(String userId) async {
    try {
      final remote = await _schoolRepo.getSchoolForUser(userId);

      // Update if anything important changed
      final changed = (_activeSchool == null) ||
          (_activeSchool!.id != remote.id) ||
          (_activeSchool!.name != remote.name);

      if (changed) {
        _activeSchool = remote;
        notifyListeners();
      }
    } catch (_) {
      // Silent fail is OK here: we already have cache + powersync running.
    }
  }

  Future<void> _connectPowerSync() async {
    if (_activeSchool == null) return;

    debugPrint("🔌 Connecting PowerSync...");
    final connector = SupaConnector(
      schoolId: _activeSchool!.id,
      supabaseClient: Supabase.instance.client,
    );
    await DatabaseService().connect(connector);
  }

  // ---------------------------------------------------------------------------
  // 3) USER ACTIONS
  // ---------------------------------------------------------------------------

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authRepo.signInWithPassword(email, password);
      final userId = response.user?.id;

      if (userId == null) {
        throw Exception("Login succeeded but userId is null.");
      }

      // Must succeed on initial login: fetch school online + cache + connect powersync
      await _fetchSchoolOnline(userId);
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final userId = _authRepo.currentUser?.id;

    try {
      await _authRepo.signOut();
    } catch (_) {
      // ignore
    }

    try {
      await DatabaseService().close();
    } catch (_) {
      // ignore
    }

    // Clear state
    _activeSchool = null;
    _requiresOnlineSetup = false;

    // Clear user-scoped cache (if we still know userId)
    if (userId != null) {
      await _schoolRepo.clearCache(userId);
    }

    notifyListeners();
  }
}
