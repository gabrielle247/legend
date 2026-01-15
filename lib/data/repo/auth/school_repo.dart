import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolException implements Exception {
  final String message;
  SchoolException(this.message);
  @override
  String toString() => message;
}

class SchoolRepository {
  final SupabaseClient _supabase;
  static const String _storageKey = 'cached_school_config';

  SchoolRepository(this._supabase);

  // ---------------------------------------------------------------------------
  // 1. LOCAL CACHE (OFFLINE FIRST STARTUP)
  // ---------------------------------------------------------------------------
  
  /// Tries to load the School Config from device storage.
  /// Returns NULL if no data is found (requiring an online fetch).
  Future<SchoolConfig?> getLocalSchool() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      
      if (jsonStr != null) {
        debugPrint("✅ [SchoolRepo] Loaded School from Local Cache");
        final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
        return SchoolConfig.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint("⚠️ [SchoolRepo] Cache read failed: $e");
    }
    return null;
  }

  /// Saves the SchoolConfig to local storage for the next app launch.
  Future<void> _saveLocalSchool(SchoolConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(config.toJson()));
    } catch (e) {
      debugPrint("⚠️ [SchoolRepo] Cache write failed: $e");
    }
  }

  /// Clears the cache on Logout to ensure security.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // ---------------------------------------------------------------------------
  // 2. REMOTE FETCH (SYNC & VERIFY)
  // ---------------------------------------------------------------------------

  /// Fetches the authoritative School Config from Supabase.
  /// If successful, it updates the Local Cache.
  Future<SchoolConfig> getSchoolForUser(String userId) async {
    try {
      debugPrint("🌐 [SchoolRepo] Fetching remote config for: $userId");

      // STEP 1: Find which school this user belongs to (via Profiles)
      final profileResponse = await _supabase
          .schema('legend')
          .from('profiles')
          .select('school_id')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        throw SchoolException("Profile not found. Please contact support.");
      }

      if (profileResponse['school_id'] == null) {
        debugPrint("User exists but is not linked to a school.");
        throw SchoolException("You are not linked to any school. Contact Admin.");
      }

      final String schoolId = profileResponse['school_id'];

      // STEP 2: Fetch the School Configuration
      final configResponse = await _supabase
          .schema('legend')
          .from('config')
          .select()
          .eq('id', schoolId)
          .maybeSingle();

      if (configResponse == null) {
        throw SchoolException("Critical: School configuration is missing.");
      }
      
      debugPrint("✅ [SchoolRepo] Remote School '${configResponse['school_name']}' Found.");

      final config = SchoolConfig.fromJson(configResponse);

      // STEP 3: Update Cache immediately
      await _saveLocalSchool(config);

      return config;

    } on PostgrestException catch (e) {
      debugPrint("DB ERROR: ${e.message}");
      throw SchoolException("Database Access Error: ${e.message}");
    } catch (e) {
      debugPrint("SYSTEM ERROR: $e");
      // If we are offline, this throws. The Auth Service catches it 
      // and decides whether to use the cache or show the "Security Screen".
      throw SchoolException("Could not verify school online.");
    }
  }

  // ---------------------------------------------------------------------------
  // 3. SCHOOL CREATION (Admin Only)
  // ---------------------------------------------------------------------------
  Future<SchoolConfig> createSchool({
    required String ownerId,
    required String schoolName,
    String currency = 'USD',
  }) async {
    try {
      final response = await _supabase
          .schema('legend')
          .from('config')
          .insert({
            'owner_id': ownerId,
            'school_name': schoolName,
            'currency': currency,
          })
          .select()
          .single();

      final config = SchoolConfig.fromJson(response);
      
      // Cache immediately so the user can start working
      await _saveLocalSchool(config);
      
      return config;
    } catch (e) {
      throw SchoolException("Failed to register new school.");
    }
  }
}