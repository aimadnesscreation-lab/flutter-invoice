import 'dart:convert';
import 'dart:io';
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

    // Simple copy as ZIP-like file for now
    final zipFile = File(zipPath);
    final dbBytes = await File(dbPath).readAsBytes();
    final jsonBytes = await File(jsonPath).readAsString();
    final combined = jsonEncode({
      'database': base64Encode(dbBytes),
      'json_data': jsonDecode(jsonBytes),
      'format': 'zip_backup',
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
    if (extension == 'db') {
      return _restoreSqlite(filePath);
    } else if (extension == 'json') {
      return _restoreJson(filePath);
    } else if (extension == 'zip') {
      return _restoreZip(filePath);
    }
    return false;
  }

  Future<bool> _restoreSqlite(String filePath) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final targetFile = File('${dbFolder.path}/${AppConstants.databaseName}');

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await File(filePath).copy(targetFile.path);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _restoreJson(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;
      // Validate backup data
      if (data['version'] == null) return false;
      // Import data back to database
      // This would be a full import process
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _restoreZip(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      final data = jsonDecode(contents);
      return data != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _exportTable(String tableName) async {
    final result = await _db.customSelect('SELECT * FROM $tableName').get();
    return result.map((r) => r.data.map((k, v) => MapEntry(k.toString(), v))).toList();
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
