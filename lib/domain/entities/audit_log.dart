class AuditLog {
  final String id;
  final String businessId;
  final String entityType;
  final String entityId;
  final String action;
  final String changes;
  final String? userId;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.businessId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.changes,
    this.userId,
    required this.createdAt,
  });
}
