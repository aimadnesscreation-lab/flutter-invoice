import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/domain/repositories/trash_repository.dart';

class TrashRepositoryImpl implements TrashRepository {
  final AppDatabase _db;

  TrashRepositoryImpl(this._db);

  @override
  Future<void> moveToTrash(
      String businessId, String entityType, String entityId, String entityData) async {
    final now = DateTime.now();
    const expiryDays = 30;

    await _db.into(_db.deletedItems).insert(DeletedItemsCompanion.insert(
      id: const Uuid().v4(),
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      entityData: entityData,
      deletedAt: now.millisecondsSinceEpoch,
      expiresAt: now.add(const Duration(days: expiryDays)).millisecondsSinceEpoch,
    ));
  }

  @override
  Future<List<Map<String, dynamic>>> getTrashItems(
      String businessId, {int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Purge expired items first
    await (_db.deletedItems.delete()
      ..where((t) => t.expiresAt.isSmallerThanValue(now))).go();

    final rows = await (_db.deletedItems.select()
      ..where((t) => t.businessId.equals(businessId))
      ..orderBy([OrderingTerm.desc(_db.deletedItems.deletedAt)])
      ..limit(pageSize, offset: offset)).get();

    return rows.map((row) => <String, dynamic>{
      'id': row.id,
      'business_id': row.businessId,
      'entity_type': row.entityType,
      'entity_id': row.entityId,
      'entity_data': row.entityData,
      'deleted_at': row.deletedAt,
      'expires_at': row.expiresAt,
    }).toList();
  }

  @override
  Future<void> restoreFromTrash(String id) async {
    await _db.transaction(() async {
      final row = await (_db.deletedItems.select()
        ..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return;

      final entityType = row.entityType;
      final entityId = row.entityId;
      final entityData = row.entityData;

      // Parse the entity data and restore accordingly
      final data = jsonDecode(entityData) as Map<String, dynamic>;

      switch (entityType) {
        case 'customer':
          await _restoreCustomer(entityId, data);
          break;
        case 'product':
          await _restoreProduct(entityId, data);
          break;
        case 'invoice':
          await _restoreInvoice(entityId);
          break;
        case 'estimate':
          await _restoreEstimate(entityId);
          break;
        case 'expense':
          await _restoreExpense(entityId);
          break;
        case 'supplier':
          await _restoreSupplier(entityId);
          break;
        case 'business':
          await _restoreBusiness(entityId);
          break;
      }

      // Remove from trash
      await (_db.deletedItems.delete()..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<void> permanentlyDelete(String id) async {
    await (_db.deletedItems.delete()..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> emptyTrash(String businessId) async {
    await (_db.deletedItems.delete()
      ..where((t) => t.businessId.equals(businessId))).go();
  }

  /// Restores a soft-deleted entity by clearing its deletedAt timestamp.
  /// The full entity data JSON is stored for reference; actual row data
  /// remains intact from the soft-delete mechanism used across the app.
  Future<void> _restoreCustomer(String id, Map<String, dynamic> _) async {
    await (_db.customers.update()..where((t) => t.id.equals(id))).write(
      const CustomersCompanion(deletedAt: Value(null)),
    );
  }

  Future<void> _restoreProduct(String id, Map<String, dynamic> _) async {
    await (_db.products.update()..where((t) => t.id.equals(id))).write(
      const ProductsCompanion(deletedAt: Value(null)),
    );
  }

  Future<void> _restoreInvoice(String id) async {
    await (_db.invoices.update()..where((t) => t.id.equals(id))).write(
      const InvoicesCompanion(deletedAt: Value(null)),
    );
  }

  Future<void> _restoreEstimate(String id) async {
    await (_db.estimates.update()..where((t) => t.id.equals(id))).write(
      const EstimatesCompanion(deletedAt: Value(null)),
    );
  }

  Future<void> _restoreExpense(String id) async {
    await (_db.expenses.update()..where((t) => t.id.equals(id))).write(
      const ExpensesCompanion(deletedAt: Value(null)),
    );
  }

  Future<void> _restoreSupplier(String id) async {
    await (_db.suppliers.update()..where((t) => t.id.equals(id))).write(
      const SuppliersCompanion(deletedAt: Value(null)),
    );
  }

  Future<void> _restoreBusiness(String id) async {
    await (_db.businesses.update()..where((t) => t.id.equals(id))).write(
      const BusinessesCompanion(deletedAt: Value(null)),
    );
  }
}
