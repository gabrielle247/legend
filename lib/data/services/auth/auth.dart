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
  bool _requiresOnlineSetup = false; // <--- The Flag for your Security Screen

  // GETTERS
  User? get user => _authRepo.currentUser;
  SchoolConfig? get activeSchool => _activeSchool;
  bool get isLoading => _isLoading;
  
  /// If TRUE, redirect user to the "Security Explanation" screen.
  /// This happens when: User has Session + No Local School Data + No Internet.
  bool get requiresOnlineSetup => _requiresOnlineSetup;

  /// FIX: Added missing getter for Router checks
  bool get isAuthenticated => _authRepo.currentUser != null;

  AuthService(this._authRepo, this._schoolRepo) {
    _restoreSession();
  }

  /// --------------------------------------------------------------------------
  /// 1. SESSION RESTORATION (OFFLINE FIRST LOGIC)
  /// --------------------------------------------------------------------------
  Future<void> _restoreSession() async {
    final userId = _authRepo.currentUser?.id;
    
    if (userId != null) {
      debugPrint("🔄 Restoring session for: $userId");
      
      try {
        // A. TRY LOCAL CACHE FIRST (Instant, works offline)
        _activeSchool = await _schoolRepo.getLocalSchool();

        if (_activeSchool != null) {
          debugPrint("✅ Offline Session Restored: ${_activeSchool!.name}");
          _requiresOnlineSetup = false;
          // Ignite PowerSync immediately with cached config
          await _connectPowerSync(); 
          
          // Optional: Attempt background refresh without blocking UI
          _backgroundRefresh(userId);
        } else {
          // B. NO CACHE? MUST GO ONLINE
          debugPrint("⚠️ No local school found. Attempting online fetch...");
          await _fetchSchoolOnline(userId);
        }

      } catch (e) {
        debugPrint("❌ Session Restoration Failed: $e");
        
        // C. EDGE CASE: User is 'Auth'd' but has no School Data & No Internet.
        // We set this flag to tell the UI to show the "Security/Online" screen.
        if (_activeSchool == null) {
          _requiresOnlineSetup = true;
        }
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// --------------------------------------------------------------------------
  /// 2. HELPERS
  /// --------------------------------------------------------------------------
  
  /// Syncs with Supabase to get the latest School Config
  Future<void> _fetchSchoolOnline(String userId) async {
    try {
      // This throws an error if offline, triggering the catch block above
      _activeSchool = await _schoolRepo.getSchoolForUser(userId);
      _requiresOnlineSetup = false;
      await _connectPowerSync();
    } catch (e) {
      // Propagate error so _restoreSession knows we failed
      throw Exception("Online fetch failed: $e");
    }
  }

  /// Fire-and-forget update to keep local cache fresh
  Future<void> _backgroundRefresh(String userId) async {
    try {
      final remote = await _schoolRepo.getSchoolForUser(userId);
      if (_activeSchool?.id != remote.id) {
        _activeSchool = remote;
        notifyListeners(); // Only update if school actually changed
      }
    } catch (_) {
      // Silent fail is fine here - we are already running on cache
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

  /// --------------------------------------------------------------------------
  /// 3. USER ACTIONS
  /// --------------------------------------------------------------------------

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Auth with Supabase
      final response = await _authRepo.signInWithPassword(email, password);
      final userId = response.user?.id;

      if (userId != null) {
        // 2. Fetch School (Must succeed on initial login)
        await _fetchSchoolOnline(userId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepo.signOut();
    await DatabaseService().close();
    
    // Clear state
    _activeSchool = null;
    _requiresOnlineSetup = false;
    
    // Clear local cache to ensure security on logout
    await _schoolRepo.clearCache(); 
    
    notifyListeners();
  }
}