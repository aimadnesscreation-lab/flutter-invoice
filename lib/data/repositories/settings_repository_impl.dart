import 'package:drift/drift.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _db;

  SettingsRepositoryImpl(this._db);

  @override
  Future<String?> getSetting(String key) async {
    final row = await (_db.appSettings.select()
      ..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    final now = DateTime.now();
    final existing = await getSetting(key);
    if (existing != null) {
      await (_db.appSettings.delete()
        ..where((t) => t.key.equals(key))).go();
    }
    await _db.into(_db.appSettings).insert(AppSettingsCompanion.insert(
      key: key,
      value: value,
      updatedAt: now.millisecondsSinceEpoch,
    ));
  }

  @override
  Future<Map<String, String>> getAllSettings() async {
    final rows = await _db.appSettings.select().get();
    final map = <String, String>{};
    for (final row in rows) {
      map[row.key] = row.value;
    }
    return map;
  }
}
