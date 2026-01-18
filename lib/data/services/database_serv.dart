// ==========================================
// FILE: ./services/database_serv.dart
// ==========================================

import 'package:flutter/foundation.dart';
import 'package:legend/data/services/powersync/powersync_factory.dart';
import 'package:powersync/powersync.dart';

class DatabaseService {
  // Singleton Pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  PowerSyncDatabase? _db;
  bool _isInitialized = false;

  /// Accessor for the DB instance. 
  /// Throws a clear error if accessed too early.
  PowerSyncDatabase get db {
    if (_db == null || !_isInitialized) {
      throw Exception("🚨 DATA LAYER ERROR: Database accessed before initialization. Call initializeStandalone() first.");
    }
    return _db!;
  }

  PowerSyncDatabase? get dbOrNull => _isInitialized ? _db : null;

  SyncStatus? get currentStatus => _isInitialized ? _db?.currentStatus : null;

  Stream<SyncStatus> get statusStream =>
      _isInitialized && _db != null ? _db!.statusStream : const Stream.empty();

  /// 1. Initialize the SQLite file (Offline Mode)
  /// Call this in main.dart before runApp()
  Future<void> initializeStandalone() async {
    if (_isInitialized) return;

    try {
      _db = await PowerSyncFactory.openDatabase();
      _isInitialized = true;
      debugPrint("✅ Database (Offline) Ready");
    } catch (e) {
      debugPrint("❌ Database Init Failed: $e");
      rethrow;
    }
  }

  /// 2. Connect to the Cloud (Online Mode)
  /// Call this in AuthService after login
  Future<void> connect(PowerSyncBackendConnector connector) async {
    if (!_isInitialized) await initializeStandalone();

    try {
      _db!.connect(connector: connector);
      debugPrint("✅ Database Connecting to Cloud...");
    } catch (e) {
      debugPrint("❌ Database Connection Failed: $e");
    }
  }

  /// 3. Clean up
  Future<void> close() async {
    await _db?.disconnect();
    debugPrint("🔒 Database Disconnected");
  }
}

// Global accessor for cleaner code in Repositories
PowerSyncDatabase get db => DatabaseService().db;
