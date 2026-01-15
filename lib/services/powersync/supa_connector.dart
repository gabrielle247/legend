import 'package:flutter/foundation.dart';
import 'package:legend/constants/env.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupaConnector extends PowerSyncBackendConnector {
  final String schoolId;
  final SupabaseClient supabaseClient;

  SupaConnector({required this.schoolId, required this.supabaseClient});

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabaseClient.auth.currentSession;
    if (session == null) return null;

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
        final data = op.opData;

        if (op.op == UpdateType.put) {
          await rest.from(table).upsert({...?data, 'id': id});
        } else if (op.op == UpdateType.patch && data != null) {
          await rest.from(table).update(data).eq('id', id);
        } else if (op.op == UpdateType.delete) {
          await rest.from(table).delete().eq('id', id);
        }
      }
      await transaction.complete();
    } catch (e) {
      debugPrint("🔥 Upload Error: $e");
      rethrow;
    }
  }
}
