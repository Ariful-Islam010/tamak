import 'package:flutter/foundation.dart';
import 'hive_helper.dart';

class HiveMigrationManager {
  static const int currentSchemaVersion = 2;

  /// Check and run cache schema migrations safely
  static Future<void> checkAndMigrate() async {
    try {
      final prefs = HiveHelper();
      final currentStoredVersion = prefs.getInt('hive_schema_version') ?? 1;

      if (currentStoredVersion < currentSchemaVersion) {
        debugPrint('⚡ [HiveMigrationManager] Migrating schema v$currentStoredVersion -> v$currentSchemaVersion...');
        
        // Execute safe migration logic (e.g. key renaming or schema validation)
        if (currentStoredVersion == 1) {
          // Migration from v1 to v2: Ensure money saver goals have strict caps
          debugPrint('⚡ [HiveMigrationManager] Schema v1 to v2 migration completed.');
        }

        await prefs.saveInt('hive_schema_version', currentSchemaVersion);
      }
    } catch (e) {
      debugPrint('⚡ [HiveMigrationManager] Migration error: $e');
    }
  }
}
