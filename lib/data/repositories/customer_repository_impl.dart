import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/customer_model.dart';
import 'package:invoice_pro/domain/entities/customer.dart' as domain;
import 'package:invoice_pro/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final AppDatabase _db;

  CustomerRepositoryImpl(this._db);

  @override
  Future<List<domain.Customer>> getAllCustomers(String businessId, {String? searchQuery, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    var allRows = await (_db.customers.select()
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

    return paged.map((row) {
      return CustomerModel.fromMap(_rowToMap(row)).toEntity();
    }).toList();
  }

  @override
  Future<domain.Customer?> getCustomerById(String id) async {
    final row = await (_db.customers.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return CustomerModel.fromMap(_rowToMap(row)).toEntity();
  }

  @override
  Future<domain.Customer> createCustomer(domain.Customer customer) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final model = CustomerModel(
      id: id,
      businessId: customer.businessId,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      taxNumber: customer.taxNumber,
      notes: customer.notes,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.customers).insert(CustomersCompanion.insert(
      id: model.id,
      businessId: model.businessId,
      name: model.name,
      phone: Value(model.phone),
      email: Value(model.email),
      address: Value(model.address),
      taxNumber: Value(model.taxNumber),
      notes: Value(model.notes),
      createdAt: model.createdAt.millisecondsSinceEpoch,
      updatedAt: model.updatedAt.millisecondsSinceEpoch,
    ));
    return model.toEntity();
  }

  @override
  Future<domain.Customer> updateCustomer(domain.Customer customer) async {
    final model = CustomerModel.fromEntity(customer);
    final updated = CustomerModel(
      id: model.id,
      businessId: model.businessId,
      name: model.name,
      phone: model.phone,
      email: model.email,
      address: model.address,
      taxNumber: model.taxNumber,
      notes: model.notes,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: model.deletedAt,
    );
    await (_db.customers.update()
      ..where((t) => t.id.equals(updated.id))).write(CustomersCompanion(
        name: Value(updated.name),
        phone: Value(updated.phone),
        email: Value(updated.email),
        address: Value(updated.address),
        taxNumber: Value(updated.taxNumber),
        notes: Value(updated.notes),
        updatedAt: Value(updated.updatedAt.millisecondsSinceEpoch),
        deletedAt: Value(updated.deletedAt?.millisecondsSinceEpoch),
      ));
    return updated.toEntity();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await (_db.customers.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> restoreCustomer(String id) async {
    // Implementation for restore
  }

  @override
  Future<int> getCustomerCount(String businessId) async {
    final rows = await (_db.customers.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    return rows.length;
  }

  @override
  Future<Map<String, dynamic>> getCustomerStats(String businessId) async {
    final customers = await (_db.customers.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    return {
      'total': customers.length,
    };
  }

  @override
  Future<List<domain.Customer>> getTopCustomers(String businessId, {int limit = 10}) async {
    final rows = await (_db.customers.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())
      ..limit(limit)).get();
    return rows.map((r) => CustomerModel.fromMap(_rowToMap(r)).toEntity()).toList();
  }

  @override
  Future<List<domain.Customer>> getOutstandingCustomers(String businessId, {int limit = 10}) async {
    return getTopCustomers(businessId, limit: limit);
  }

  Map<String, dynamic> _rowToMap(Customer row) {
    return {
      'id': row.id,
      'business_id': row.businessId,
      'name': row.name,
      'phone': row.phone,
      'email': row.email,
      'address': row.address,
      'tax_number': row.taxNumber,
      'notes': row.notes,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'deleted_at': row.deletedAt,
    };
  }
}
