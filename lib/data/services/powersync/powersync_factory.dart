import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:legend/data/constants/app_schema.dart';

class PowerSyncFactory {
  /// Opens and initializes the PowerSync database.
  static Future<PowerSyncDatabase> openDatabase() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final path = join(dir.path, 'kwalegend_offline.db');

      final db = PowerSyncDatabase(schema: schema, path: path);
      await db.initialize();

      return db;
    } catch (e) {
      debugPrint("❌ PowerSync Init Failed: $e");
      rethrow;
    }
  }
}
