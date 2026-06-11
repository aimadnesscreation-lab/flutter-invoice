import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/domain/entities/supplier.dart' as domain;
import 'package:invoice_pro/domain/repositories/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final AppDatabase _db;

  SupplierRepositoryImpl(this._db);

  @override
  Future<List<domain.Supplier>> getAllSuppliers(String businessId, {String? searchQuery, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    final query = _db.select(_db.suppliers)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull());

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final term = '%$searchQuery%';
      query.where((t) =>
        t.name.like(term) |
        t.email.like(term) |
        t.phone.like(term)
      );
    }

    query.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    query.limit(pageSize, offset: offset);

    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<domain.Supplier?> getSupplierById(String id) async {
    final row = await (_db.suppliers.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<domain.Supplier> createSupplier(domain.Supplier supplier) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await _db.into(_db.suppliers).insert(SuppliersCompanion.insert(
      id: id,
      businessId: supplier.businessId,
      name: supplier.name,
      phone: Value(supplier.phone),
      email: Value(supplier.email),
      address: Value(supplier.address),
      taxNumber: Value(supplier.taxNumber),
      contactPerson: Value(supplier.contactPerson),
      notes: Value(supplier.notes),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    ));
    await _logAudit(supplier.businessId, 'supplier', id, 'create', 'Created supplier ${supplier.name}');
    return supplier.copyWith(id: id, createdAt: now, updatedAt: now);
  }

  @override
  Future<domain.Supplier> updateSupplier(domain.Supplier supplier) async {
    final now = DateTime.now();
    await (_db.suppliers.update()
      ..where((t) => t.id.equals(supplier.id))).write(SuppliersCompanion(
        name: Value(supplier.name),
        phone: Value(supplier.phone),
        email: Value(supplier.email),
        address: Value(supplier.address),
        taxNumber: Value(supplier.taxNumber),
        contactPerson: Value(supplier.contactPerson),
        notes: Value(supplier.notes),
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(supplier.deletedAt?.millisecondsSinceEpoch),
      ));
    await _logAudit(supplier.businessId, 'supplier', supplier.id, 'update', 'Updated supplier ${supplier.name}');
    return supplier.copyWith(updatedAt: now);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    final supplier = await getSupplierById(id);
    await (_db.suppliers.update()
      ..where((t) => t.id.equals(id))).write(SuppliersCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    if (supplier != null) {
      await _logAudit(supplier.businessId, 'supplier', id, 'delete', 'Deleted supplier ${supplier.name}');
    }
  }

  @override
  Future<void> restoreSupplier(String id) async {
    await (_db.suppliers.update()
      ..where((t) => t.id.equals(id))).write(const SuppliersCompanion(
        deletedAt: Value(null),
      ));
  }

  domain.Supplier _toEntity(Supplier row) {
    return domain.Supplier(
      id: row.id,
      businessId: row.businessId,
      name: row.name,
      phone: row.phone,
      email: row.email,
      address: row.address,
      taxNumber: row.taxNumber,
      contactPerson: row.contactPerson,
      notes: row.notes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  Future<void> _logAudit(String businessId, String entityType, String entityId, String action, String changes) async {
    await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
      id: const Uuid().v4(),
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      changes: changes,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}
