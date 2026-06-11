import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  Future<String> createSqliteBackup() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final sourceFile = File('${dbFolder.path}/${AppConstants.databaseName}');

    final backupDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File('${backupDir.path}/${AppConstants.backupFileNamePattern}$timestamp.db');

    if (await sourceFile.exists()) {
      await backupFile.writeAsBytes(await sourceFile.readAsBytes());
    }

    return backupFile.path;
  }

  Future<String> createJsonBackup() async {
    final backup = <String, dynamic>{};

    backup['businesses'] = await _exportTable('businesses');
    backup['customers'] = await _exportTable('customers');
    backup['suppliers'] = await _exportTable('suppliers');
    backup['products'] = await _exportTable('products');
    backup['categories'] = await _exportTable('product_categories');
    backup['invoices'] = await _exportTable('invoices');
    backup['invoice_items'] = await _exportTable('invoice_items');
    backup['payments'] = await _exportTable('payments');
    backup['estimates'] = await _exportTable('estimates');
    backup['estimate_items'] = await _exportTable('estimate_items');
    backup['expenses'] = await _exportTable('expenses');
    backup['credit_notes'] = await _exportTable('credit_notes');
    backup['tax_rates'] = await _exportTable('tax_rates');
    backup['currencies'] = await _exportTable('currencies');
    backup['settings'] = await _exportTable('app_settings');
    backup['version'] = 1;
    backup['created_at'] = DateTime.now().toIso8601String();

    final backupDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${backupDir.path}/${AppConstants.backupFileNamePattern}$timestamp.json');
    await file.writeAsString(jsonEncode(backup));

    return file.path;
  }

  Future<String> createZipBackup() async {
    final dbPath = await createSqliteBackup();
    final jsonPath = await createJsonBackup();

    final backupDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = '${backupDir.path}/${AppConstants.backupFileNamePattern}$timestamp.zip';

    final zipFile = File(zipPath);
    final dbBytes = await File(dbPath).readAsBytes();
    final jsonBytes = await File(jsonPath).readAsString();
    final combined = jsonEncode({
      'format': 'invoice_pro_zip_backup',
      'version': 1,
      'created_at': DateTime.now().toIso8601String(),
      'database': base64Encode(dbBytes),
      'json_data': jsonDecode(jsonBytes),
    });
    await zipFile.writeAsString(combined);

    // Cleanup temp files
    await File(dbPath).delete();
    await File(jsonPath).delete();

    return zipPath;
  }

  Future<bool> restoreFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final extension = filePath.split('.').last.toLowerCase();
    try {
      if (extension == 'db') {
        return _restoreSqlite(filePath);
      } else if (extension == 'json') {
        return _restoreJson(filePath);
      } else if (extension == 'zip') {
        return _restoreZip(filePath);
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<bool> _restoreSqlite(String filePath) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final targetFile = File('${dbFolder.path}/${AppConstants.databaseName}');

    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await File(filePath).copy(targetFile.path);
    return true;
  }

  Future<bool> _restoreJson(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();
    final data = jsonDecode(contents) as Map<String, dynamic>;

    if (data['version'] == null) return false;

    await _db.transaction(() async {
      // Clear existing data in reverse dependency order using custom statements
      await _db.customStatement('DELETE FROM audit_logs');
      await _db.customStatement('DELETE FROM deleted_items');
      await _db.customStatement('DELETE FROM invoice_items');
      await _db.customStatement('DELETE FROM invoices');
      await _db.customStatement('DELETE FROM estimate_items');
      await _db.customStatement('DELETE FROM estimates');
      await _db.customStatement('DELETE FROM payments');
      await _db.customStatement('DELETE FROM credit_notes');
      await _db.customStatement('DELETE FROM expenses');
      await _db.customStatement('DELETE FROM inventory_transactions');
      await _db.customStatement('DELETE FROM products');
      await _db.customStatement('DELETE FROM product_categories');
      await _db.customStatement('DELETE FROM suppliers');
      await _db.customStatement('DELETE FROM customers');
      await _db.customStatement('DELETE FROM businesses');
      await _db.customStatement('DELETE FROM tax_rates');
      await _db.customStatement('DELETE FROM currencies');
      await _db.customStatement('DELETE FROM app_settings');
      await _db.customStatement('DELETE FROM invoice_numbering');

      // Restore data in dependency order
      for (final row in (data['businesses'] as List?) ?? []) {
        await _insertRow('businesses', row);
      }
      for (final row in (data['customers'] as List?) ?? []) {
        await _insertRow('customers', row);
      }
      for (final row in (data['suppliers'] as List?) ?? []) {
        await _insertRow('suppliers', row);
      }
      for (final row in (data['categories'] as List?) ?? []) {
        await _insertRow('product_categories', row);
      }
      for (final row in (data['products'] as List?) ?? []) {
        await _insertRow('products', row);
      }
      for (final row in (data['invoices'] as List?) ?? []) {
        await _insertRow('invoices', row);
      }
      for (final row in (data['invoice_items'] as List?) ?? []) {
        await _insertRow('invoice_items', row);
      }
      for (final row in (data['payments'] as List?) ?? []) {
        await _insertRow('payments', row);
      }
      for (final row in (data['estimates'] as List?) ?? []) {
        await _insertRow('estimates', row);
      }
      for (final row in (data['estimate_items'] as List?) ?? []) {
        await _insertRow('estimate_items', row);
      }
      for (final row in (data['expenses'] as List?) ?? []) {
        await _insertRow('expenses', row);
      }
      for (final row in (data['credit_notes'] as List?) ?? []) {
        await _insertRow('credit_notes', row);
      }
      for (final row in (data['tax_rates'] as List?) ?? []) {
        await _insertRow('tax_rates', row);
      }
      for (final row in (data['currencies'] as List?) ?? []) {
        await _insertRow('currencies', row);
      }
      for (final row in (data['settings'] as List?) ?? []) {
        await _insertRow('app_settings', row);
      }
    });

    return true;
  }

  Future<void> _insertRow(String table, Map<String, dynamic> row) async {
    final columns = row.keys.map((k) => '"$k"').join(', ');
    final placeholders = row.keys.map((_) => '?').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders)';
    final values = row.values.map((v) => Variable(v)).toList();
    await _db.customInsert(sql, variables: values);
  }

  Future<bool> _restoreZip(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();
    final data = jsonDecode(contents) as Map<String, dynamic>;

    if (data['format'] != 'invoice_pro_zip_backup') return false;

    // Restore from JSON data within the ZIP backup
    if (data['json_data'] != null) {
      final tmpJsonPath = filePath.replaceAll('.zip', '_restore.json');
      final tmpFile = File(tmpJsonPath);
      await tmpFile.writeAsString(jsonEncode(data['json_data']));
      final result = await _restoreJson(tmpJsonPath);
      await tmpFile.delete();
      return result;
    }

    // Fallback: restore from embedded database
    if (data['database'] != null) {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbBytes = base64Decode(data['database'] as String);
      final targetFile = File('${dbFolder.path}/${AppConstants.databaseName}');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await targetFile.writeAsBytes(dbBytes);
      return true;
    }

    return false;
  }

  Future<List<Map<String, dynamic>>> _exportTable(String tableName) async {
    final result = await _db.customSelect('SELECT * FROM "$tableName"').get();
    return result.map((r) {
      final row = <String, dynamic>{};
      for (final entry in r.data.entries) {
        row[entry.key.toString()] = entry.value;
      }
      return row;
    }).toList();
  }

  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'json', 'zip'],
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first.path;
  }

  Future<String?> pickExportDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    return result;
  }
}
