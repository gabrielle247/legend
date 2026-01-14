import 'package:flutter/foundation.dart';
import 'package:legend/models/legend.dart';
import 'package:legend/repo/auth/auth.dart';
import 'package:legend/repo/auth/school_repo.dart';
import 'package:legend/services/database_serv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final AuthRepository _authRepo;
  final SchoolRepository _schoolRepo;

  AuthService(this._authRepo, this._schoolRepo);

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
          await DatabaseService().connectToSchool(_activeSchool!.id);
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
