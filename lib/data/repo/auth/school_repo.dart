import 'package:flutter/foundation.dart' show debugPrint;
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
  static const String _storagePrefix = 'cached_school_config';

  SchoolRepository(this._supabase);

  static String _keyForUser(String userId) => '$_storagePrefix:$userId';

  // ---------------------------------------------------------------------------
  // 1) LOCAL CACHE (OFFLINE FIRST STARTUP)
  // ---------------------------------------------------------------------------

  Future<SchoolConfig?> getLocalSchool(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyForUser(userId));
      if (jsonStr == null) return null;

      final Map<String, dynamic> envelope = jsonDecode(jsonStr);

      // Hard ownership check (prevents cross-user bleed)
      if (envelope['userId'] != userId) return null;

      final Map<String, dynamic> configJson =
          (envelope['config'] as Map).cast<String, dynamic>();

      debugPrint("✅ [SchoolRepo] Loaded School from Local Cache");
      return SchoolConfig.fromJson(configJson);
    } catch (e) {
      debugPrint("⚠️ [SchoolRepo] Cache read failed: $e");
      return null;
    }
  }

  Future<void> _saveLocalSchool(String userId, SchoolConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final envelope = {
        'userId': userId,
        'cachedAt': DateTime.now().toIso8601String(),
        'config': config.toJson(),
      };

      await prefs.setString(_keyForUser(userId), jsonEncode(envelope));
    } catch (e) {
      debugPrint("⚠️ [SchoolRepo] Cache write failed: $e");
    }
  }

  Future<void> clearCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForUser(userId));
  }

  // ---------------------------------------------------------------------------
  // 2) REMOTE FETCH (VERIFY + CACHE)
  // ---------------------------------------------------------------------------

  Future<SchoolConfig> getSchoolForUser(String userId) async {
    try {
      debugPrint("🌐 [SchoolRepo] Fetching remote config for: $userId");

      final profile = await _supabase
          .schema('legend')
          .from('profiles')
          .select('school_id')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        throw SchoolException("Profile not found.");
      }

      final schoolId = profile['school_id'] as String?;
      if (schoolId == null || schoolId.isEmpty) {
        throw SchoolException("You are not linked to any school.");
      }

      final configRow = await _supabase
          .schema('legend')
          .from('config')
          .select()
          .eq('id', schoolId)
          .maybeSingle();

      if (configRow == null) {
        throw SchoolException("Critical: School configuration is missing.");
      }

      final config = SchoolConfig.fromJson(configRow);
      await _saveLocalSchool(userId, config);

      return config;
    } on PostgrestException catch (e) {
      debugPrint("DB ERROR: ${e.message}");
      throw SchoolException("Database Access Error: ${e.message}");
    } on AuthException catch (e) {
      debugPrint("AUTH ERROR: ${e.message}");
      throw SchoolException("Auth Error: ${e.message}");
    } catch (e) {
      debugPrint("SYSTEM ERROR: $e");
      throw SchoolException("Could not verify school online.");
    }
  }

  // ---------------------------------------------------------------------------
  // 3) SCHOOL CREATION (Admin Only)
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

      // cache immediately
      await _saveLocalSchool(ownerId, config);

      return config;
    } on PostgrestException catch (e) {
      throw SchoolException("Failed to register new school: ${e.message}");
    } catch (_) {
      throw SchoolException("Failed to register new school.");
    }
  }
}
