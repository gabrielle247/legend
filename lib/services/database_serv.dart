// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:legend/constants/app_schema.dart';
import 'package:legend/app_init.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// GLOBAL ACCESS
PowerSyncDatabase? _globalDb;
// CRITICAL: This throws if called before AppInit.
PowerSyncDatabase get db {
  if (_globalDb == null) {
    throw Exception("🔥 FATAL: Database accessed before initialization!");
  }
  return _globalDb!;
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _isStandaloneInitialized = false;
  bool _isConnected = false;

  /// 1. CALLED BY MAIN > APPINIT
  Future<void> initializeStandalone() async {
    if (_isStandaloneInitialized) return;

    try {
      final dir = await getApplicationSupportDirectory();
      final path = join(dir.path, 'kwalegend_offline.db');

      _globalDb = PowerSyncDatabase(schema: schema, path: path);
      await _globalDb!.initialize();
      _isStandaloneInitialized = true;

      debugPrint("✅ PowerSync (Offline Mode) Ready");
    } catch (e) {
      debugPrint("❌ PowerSync Init Failed: $e");
      rethrow;
    }
  }

  /// 2. CALLED BY DASHBOARD VM (After Login)
  Future<void> connectToSchool(String schoolId) async {
    if (!_isStandaloneInitialized) await initializeStandalone();

    if (_isConnected) return;

    try {
      _globalDb!.connect(connector: _SupabaseConnector(_globalDb!, schoolId));
      _isConnected = true;
      debugPrint("✅ PowerSync Connected to School: $schoolId");
    } catch (e) {
      debugPrint("❌ Connection Failed: $e");
    }
  }

  /// 3. CALLED ON LOGOUT
  Future<void> close() async {
    await _globalDb?.disconnect();
    _isConnected = false;
    debugPrint("🔒 PowerSync Disconnected");
  }
}

class _SupabaseConnector extends PowerSyncBackendConnector {
  final PowerSyncDatabase db;
  final String schoolId;

  _SupabaseConnector(this.db, this.schoolId);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = Supabase.instance.client.auth.currentSession;
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

    final rest = Supabase.instance.client.schema('legend');

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
