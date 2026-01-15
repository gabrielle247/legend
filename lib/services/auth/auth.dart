import 'package:flutter/foundation.dart';
import 'package:legend/models/school_config.dart';
import 'package:legend/repo/auth/auth.dart';
import 'package:legend/repo/auth/school_repo.dart';
import 'package:legend/services/database_serv.dart';
import 'package:legend/services/powersync/supa_connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final AuthRepository _authRepo;
  final SchoolRepository _schoolRepo;

  AuthService(this._authRepo, this._schoolRepo) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final userId = _authRepo.currentUser?.id;
    if (userId != null) {
      try {
        debugPrint("🔄 Restoring session for user: $userId");
        _activeSchool = await _schoolRepo.getSchoolForUser(userId);

        if (_activeSchool != null) {
          debugPrint("Connecting PowerSync to school: ${_activeSchool!.name}");

          final connector = SupaConnector(
            schoolId: _activeSchool!.id,
            supabaseClient: Supabase.instance.client,
          );

          await DatabaseService().connect(connector);
          debugPrint("✅ Session restored & PowerSync connected");
        }
        notifyListeners();
      } catch (e) {
        debugPrint("❌ Session restore failed: $e");
      }
    }
  }

  User? get user => _authRepo.currentUser;

  bool get isAuthenticated => _authRepo.currentUser != null;

  // STATE: The currently active school for the session
  SchoolConfig? _activeSchool;
  SchoolConfig? get activeSchool => _activeSchool;

  /// Full Login Flow: Auth -> Fetch School -> Connect PowerSync -> Ready
  Future<void> login(String email, String password) async {
    // 1. Authenticate with Supabase
    final response = await _authRepo.signInWithPassword(email, password);
    final userId = response.user?.id;

    if (userId != null) {
      try {
        // 2. Fetch School configuration
        _activeSchool = await _schoolRepo.getSchoolForUser(userId);

        if (_activeSchool != null) {
          // 3. Connect PowerSync to school (start syncing data)
          debugPrint(
            "Connecting PowerSync to school: ${_activeSchool!.name}",
          );

          final connector = SupaConnector(
            schoolId: _activeSchool!.id,
            supabaseClient: Supabase.instance.client,
          );

          await DatabaseService().connect(connector);
          debugPrint("PowerSync connected & syncing");

          // 4. Wait briefly for initial sync to start
          await Future.delayed(const Duration(milliseconds: 500));
          debugPrint("Initial sync window completed");
        }

        // 5. Notify app that we are fully ready
        notifyListeners();
      } catch (e) {
        debugPrint("Auth successful, but setup failed: $e");
        rethrow;
      }
    }
  }

  Future<void> logout() async {
    await _authRepo.signOut();
    _activeSchool = null;
    notifyListeners();
  }
}
