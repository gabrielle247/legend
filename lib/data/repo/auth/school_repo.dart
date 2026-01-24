import 'package:flutter/foundation.dart' show debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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

  Future<SchoolConfig?> _findOwnedSchool(String userId) async {
    final configRow = await _supabase
        .schema('legend')
        .from('config')
        .select()
        .eq('owner_id', userId)
        .maybeSingle();

    if (configRow == null) return null;
    return SchoolConfig.fromJson(configRow);
  }

  Future<void> _upsertProfile({
    required String userId,
    String? schoolId,
    String role = 'OWNER',
    String? fullName,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    final metadataName = currentUser?.userMetadata?['full_name'];
    final resolvedName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : (metadataName is String && metadataName.trim().isNotEmpty)
            ? metadataName.trim()
            : (currentUser?.email?.trim().isNotEmpty ?? false)
                ? currentUser!.email!.trim()
                : 'User';

    final payload = <String, dynamic>{
      'id': userId,
      'school_id': schoolId,
      'role': role,
      'full_name': resolvedName,
    };

    await _supabase
        .schema('legend')
        .from('profiles')
        .upsert(payload, onConflict: 'id');
  }

  Future<bool> profileExists(String userId) async {
    final existing = await _supabase
        .schema('legend')
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    return existing != null;
  }

  Future<void> createProfile({
    required String userId,
    required String fullName,
    String role = 'OWNER',
  }) async {
    await _upsertProfile(
      userId: userId,
      schoolId: null,
      role: role,
      fullName: fullName,
    );
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
        final ownedConfig = await _findOwnedSchool(userId);
        if (ownedConfig == null) {
          throw SchoolException("Profile not found.");
        }

        await _upsertProfile(
          userId: userId,
          schoolId: ownedConfig.id,
        );
        await _saveLocalSchool(userId, ownedConfig);
        return ownedConfig;
      }

      final schoolId = profile['school_id'] as String?;
      if (schoolId == null || schoolId.isEmpty) {
        final ownedConfig = await _findOwnedSchool(userId);
        if (ownedConfig == null) {
          throw SchoolException("You are not linked to any school.");
        }

        await _upsertProfile(
          userId: userId,
          schoolId: ownedConfig.id,
        );
        await _saveLocalSchool(userId, ownedConfig);
        return ownedConfig;
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
    String? address,
    String? logoUrl,
  }) async {
    try {
      const uuid = Uuid();
      final schoolId = uuid.v4();

      final payload = <String, dynamic>{
        'id': schoolId,
        'owner_id': ownerId,
        'school_name': schoolName,
        'currency': currency,
      };

      if (address != null && address.trim().isNotEmpty) {
        payload['address'] = address.trim();
      }
      if (logoUrl != null && logoUrl.trim().isNotEmpty) {
        payload['logo_url'] = logoUrl.trim();
      }

      await _supabase.schema('legend').from('config').insert(payload);

      await _upsertProfile(userId: ownerId, schoolId: schoolId);

      final response = await _supabase
          .schema('legend')
          .from('config')
          .select()
          .eq('id', schoolId)
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
