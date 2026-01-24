// ==========================================
// FILE: ./services/powersync/supa_connector.dart
// ==========================================

import 'package:flutter/foundation.dart';
import 'package:legend/data/constants/env.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupaConnector extends PowerSyncBackendConnector {
  final String schoolId;
  final SupabaseClient supabaseClient;

  SupaConnector({required this.schoolId, required this.supabaseClient});

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabaseClient.auth.currentSession;
    if (session == null) {
      // If session is dead, we return null to pause sync rather than crash
      debugPrint("⚠️ PowerSync: No active Supabase session.");
      return null;
    }

    return PowerSyncCredentials(
      endpoint: AppEnv.powerSyncUrl,
      token: session.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    // Use the 'legend' schema for Supabase operations
    final rest = supabaseClient.schema('legend');

    try {
      for (var op in transaction.crud) {
        final table = op.table;
        final id = op.id;
        // CRITICAL FIX: Convert SQLite Integers (0/1) back to Postgres Booleans
        final data = _fixTypes(op.opData, table);

        if (op.op == UpdateType.put) {
          // Upsert: Handle both Insert and Update
          await rest.from(table).upsert({...?data, 'id': id});
        } else if (op.op == UpdateType.patch && data != null) {
          // Patch: Update specific fields
          await rest.from(table).update(data).eq('id', id);
        } else if (op.op == UpdateType.delete) {
          // Delete
          await rest.from(table).delete().eq('id', id);
        }
      }
      await transaction.complete();
    } catch (e) {
      debugPrint("🔥 Upload Error (Table: ${transaction.crud.first.table}): $e");
      // Note: We deliberately do NOT rethrow here immediately to avoid 
      // crashing the sync loop forever on one bad record. 
      // But for dev, rethrowing helps you see the error.
      rethrow; 
    }
  }

  /// Helper to sanitize types before sending to Postgres
  Map<String, dynamic>? _fixTypes(Map<String, dynamic>? data, String table) {
    if (data == null) return null;
    
    final Map<String, dynamic> fixed = Map.from(data);

    // List of columns that are BOOLEAN in Postgres but INTEGER in SQLite
    const boolColumns = [
      'is_active',
      'is_locked',
      'is_taxable',
      'is_banned',
      'is_read',
      'is_secret'
    ];

    for (var key in fixed.keys) {
      if (boolColumns.contains(key) && fixed[key] is int) {
        // Convert 1 -> true, 0 -> false
        fixed[key] = fixed[key] == 1;
      }
    }

    return fixed;
  }
}