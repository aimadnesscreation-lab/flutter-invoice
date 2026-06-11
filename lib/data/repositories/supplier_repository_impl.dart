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
    var allRows = await (_db.suppliers.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    var rows = allRows;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      rows = rows.where((r) =>
        r.name.toLowerCase().contains(query) ||
        (r.email?.toLowerCase().contains(query) ?? false) ||
        (r.phone?.contains(query) ?? false)
      ).toList();
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paged = rows.skip(offset).take(pageSize).toList();

    return paged.map(_toEntity).toList();
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
      ));
    return supplier.copyWith(updatedAt: now);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await (_db.suppliers.delete()
      ..where((t) => t.id.equals(id))).go();
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
}
