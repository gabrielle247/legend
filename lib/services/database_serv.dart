import 'package:flutter/foundation.dart';
import 'package:legend/services/powersync/powersync_factory.dart';
import 'package:powersync/powersync.dart';

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
      _globalDb = await PowerSyncFactory.openDatabase();
      _isStandaloneInitialized = true;

      debugPrint("✅ PowerSync (Offline Mode) Ready");
    } catch (e) {
      debugPrint("❌ PowerSync Init Failed: $e");
      rethrow;
    }
  }

  /// 2. CALLED BY AUTH SERVICE (After Login)
  Future<void> connect(PowerSyncBackendConnector connector) async {
    if (!_isStandaloneInitialized) await initializeStandalone();

    if (_isConnected) return;

    try {
      if (_globalDb == null) {
         throw Exception("Database not initialized");
      }

      _globalDb!.connect(connector: connector);
      _isConnected = true;
      debugPrint("✅ PowerSync Connected");
    } catch (e) {
      debugPrint("❌ Connection Failed: $e");
      rethrow;
    }
  }

  /// 3. CALLED ON LOGOUT
  Future<void> close() async {
    await _globalDb?.disconnect();
    _isConnected = false;
    debugPrint("🔒 PowerSync Disconnected");
  }
}
