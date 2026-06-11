import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/domain/entities/audit_log.dart';
import 'package:invoice_pro/domain/repositories/audit_log_repository.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AppDatabase _db;

  AuditLogRepositoryImpl(this._db);

  @override
  Future<void> logAction(AuditLog log) async {
    await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
      id: log.id.isNotEmpty ? log.id : const Uuid().v4(),
      businessId: log.businessId,
      entityType: log.entityType,
      entityId: log.entityId,
      action: log.action,
      changes: log.changes,
      userId: Value(log.userId),
      createdAt: log.createdAt.millisecondsSinceEpoch,
    ));
  }

  @override
  Future<List<AuditLog>> getLogs(
    String businessId, {
    String? entityType,
    String? entityId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final offset = (page - 1) * pageSize;

    final query = _db.select(_db.auditLogs)
      ..where((t) => t.businessId.equals(businessId))
      ..orderBy([OrderingTerm.desc(_db.auditLogs.createdAt)])
      ..limit(pageSize, offset: offset);

    if (entityType != null) {
      query.where((t) => t.entityType.equals(entityType));
    }
    if (entityId != null) {
      query.where((t) => t.entityId.equals(entityId));
    }

    final rows = await query.get();

    return rows.map((row) {
      return AuditLog(
        id: row.id,
        businessId: row.businessId,
        entityType: row.entityType,
        entityId: row.entityId,
        action: row.action,
        changes: row.changes,
        userId: row.userId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );
    }).toList();
  }
}
