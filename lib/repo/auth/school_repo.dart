import 'package:flutter/cupertino.dart';
import 'package:legend/models/legend.dart'; // Ensure SchoolConfig is in here
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolException implements Exception {
  final String message;
  SchoolException(this.message);
  @override
  String toString() => message;
}

class SchoolRepository {
  final SupabaseClient _supabase;

  SchoolRepository(this._supabase);

  /// --------------------------------------------------------------------------
  /// FETCH SCHOOL FOR USER (STAFF MODE)
  /// --------------------------------------------------------------------------
  Future<SchoolConfig> getSchoolForUser(String userId) async {
    try {
      debugPrint("🔍 (1/2) Checking Staff Profile for: $userId");

      // STEP 1: Check the 'profiles' table to see which school this user belongs to.
      // This works because we added the 'Users manage own profile' policy.
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
        debugPrint("❌ User exists but is not linked to a school.");
        throw SchoolException("You are not linked to any school. Contact Admin.");
      }

      final String schoolId = profileResponse['school_id'];
      debugPrint("✅ (1/2) Staff confirmed for School ID: $schoolId");

      // STEP 2: Fetch the School Config using the found ID.
      // This works because of the 'Staff access school config' policy.
      final configResponse = await _supabase
          .schema('legend')
          .from('config')
          .select()
          .eq('id', schoolId)
          .maybeSingle();

      if (configResponse == null) {
        throw SchoolException("Critical: Linked school configuration is missing.");
      }
      
      debugPrint("✅ (2/2) School '${configResponse['school_name']}' Loaded.");

      return SchoolConfig.fromJson(configResponse);

    } on PostgrestException catch (e) {
      debugPrint("🔥 DB ERROR: ${e.message} (Code: ${e.code})");
      throw SchoolException("Database Access Error: ${e.message}");
    } catch (e) {
      debugPrint("💥 SYSTEM ERROR: $e");
      throw SchoolException("System failure during school fetch.");
    }
  }

  /// --------------------------------------------------------------------------
  /// CREATE NEW SCHOOL
  /// --------------------------------------------------------------------------
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

      return SchoolConfig.fromJson(response);
    } catch (e) {
      throw SchoolException("Failed to register new school.");
    }
  }
}