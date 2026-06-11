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
    final query = _db.select(_db.customers)
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
    return rows.map((row) => CustomerModel.fromMap(_rowToMap(row)).toEntity()).toList();
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

    await _logAudit(customer.businessId, 'customer', id, 'create', 'Created customer ${customer.name}');
    
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

    await _logAudit(customer.businessId, 'customer', customer.id, 'update', 'Updated customer ${customer.name}');

    return updated.toEntity();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final customer = await getCustomerById(id);
    await (_db.customers.update()
      ..where((t) => t.id.equals(id))).write(CustomersCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

    if (customer != null) {
      await _logAudit(customer.businessId, 'customer', id, 'delete', 'Deleted customer ${customer.name}');
    }
  }

  @override
  Future<void> restoreCustomer(String id) async {
    await (_db.customers.update()
      ..where((t) => t.id.equals(id))).write(const CustomersCompanion(
        deletedAt: Value(null),
      ));
  }

  @override
  Future<int> getCustomerCount(String businessId) async {
    final countExp = _db.customers.id.count();
    final query = _db.selectOnly(_db.customers)
      ..addColumns([countExp])
      ..where(_db.customers.businessId.equals(businessId))
      ..where(_db.customers.deletedAt.isNull());
    
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<Map<String, dynamic>> getCustomerStats(String businessId) async {
    final total = await getCustomerCount(businessId);
    return {
      'total': total,
    };
  }

  @override
  Future<List<domain.Customer>> getTopCustomers(String businessId, {int limit = 10}) async {
    // Join with invoices to find customers with highest revenue
    final revenue = _db.invoices.grandTotal.sum();
    final query = _db.select(_db.customers).join([
      innerJoin(_db.invoices, _db.invoices.customerId.equalsExp(_db.customers.id)),
    ])
      ..where(_db.customers.businessId.equals(businessId))
      ..where(_db.customers.deletedAt.isNull())
      ..where(_db.invoices.status.equals('paid'))
      ..addColumns([revenue])
      ..groupBy([_db.customers.id])
      ..orderBy([OrderingTerm.desc(revenue)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((row) => CustomerModel.fromMap(_rowToMap(row.readTable(_db.customers))).toEntity()).toList();
  }

  @override
  Future<List<domain.Customer>> getOutstandingCustomers(String businessId, {int limit = 10}) async {
    // Join with invoices to find customers with highest balance due
    final balance = _db.invoices.balanceDue.sum();
    final query = _db.select(_db.customers).join([
      innerJoin(_db.invoices, _db.invoices.customerId.equalsExp(_db.customers.id)),
    ])
      ..where(_db.customers.businessId.equals(businessId))
      ..where(_db.customers.deletedAt.isNull())
      ..where(_db.invoices.balanceDue.isBiggerThanValue(0))
      ..addColumns([balance])
      ..groupBy([_db.customers.id])
      ..orderBy([OrderingTerm.desc(balance)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((row) => CustomerModel.fromMap(_rowToMap(row.readTable(_db.customers))).toEntity()).toList();
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
