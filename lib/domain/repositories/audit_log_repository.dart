import 'package:invoice_pro/domain/entities/audit_log.dart';

abstract class AuditLogRepository {
  Future<void> logAction(AuditLog log);
  Future<List<AuditLog>> getLogs(String businessId, {String? entityType, String? entityId, int page = 1, int pageSize = 50});
}
