import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/business_model.dart';
import 'package:invoice_pro/domain/entities/business.dart';
import 'package:invoice_pro/domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final AppDatabase _db;
  Business? _activeBusiness;

  BusinessRepositoryImpl(this._db);

  @override
  Future<List<Business>> getAllBusinesses() async {
    final rows = await _db.businesses.select().get();
    return rows.map((row) {
      final map = _rowToMap(row);
      return BusinessModel.fromMap(map).toEntity();
    }).toList();
  }

  @override
  Future<Business?> getBusinessById(String id) async {
    final rows = await _db.businesses.select().get();
    final row = rows.where((r) => r.id == id).firstOrNull;
    if (row == null) return null;
    return BusinessModel.fromMap(_rowToMap(row)).toEntity();
  }

  @override
  Future<Business> createBusiness(Business business) async {
    final id = business.id.isEmpty ? const Uuid().v4() : business.id;
    final now = DateTime.now();
    final model = BusinessModel(
      id: id,
      name: business.name,
      logoPath: business.logoPath,
      address: business.address,
      phone: business.phone,
      email: business.email,
      taxNumber: business.taxNumber,
      currency: business.currency,
      currencySymbol: business.currencySymbol,
      defaultTaxRate: business.defaultTaxRate,
      invoicePrefix: business.invoicePrefix,
      estimatePrefix: business.estimatePrefix,
      purchaseOrderPrefix: business.purchaseOrderPrefix,
      creditNotePrefix: business.creditNotePrefix,
      expensePrefix: business.expensePrefix,
      notes: business.notes,
      dateFormat: business.dateFormat,
      numberFormat: business.numberFormat,
      themeMode: business.themeMode,
      createdAt: business.createdAt.isBefore(DateTime(2020)) ? now : business.createdAt,
      updatedAt: now,
      deletedAt: business.deletedAt,
    );
    await _db.into(_db.businesses).insert(BusinessesCompanion.insert(
      id: model.id,
      name: model.name,
      logoPath: Value(model.logoPath),
      address: Value(model.address),
      phone: Value(model.phone),
      email: Value(model.email),
      taxNumber: Value(model.taxNumber),
      currency: Value(model.currency),
      currencySymbol: Value(model.currencySymbol),
      defaultTaxRate: Value(model.defaultTaxRate),
      invoicePrefix: Value(model.invoicePrefix),
      estimatePrefix: Value(model.estimatePrefix),
      purchaseOrderPrefix: Value(model.purchaseOrderPrefix),
      creditNotePrefix: Value(model.creditNotePrefix),
      expensePrefix: Value(model.expensePrefix),
      notes: Value(model.notes),
      dateFormat: Value(model.dateFormat),
      numberFormat: Value(model.numberFormat),
      themeMode: Value(model.themeMode),
      createdAt: model.createdAt.millisecondsSinceEpoch,
      updatedAt: model.updatedAt.millisecondsSinceEpoch,
      deletedAt: Value(model.deletedAt?.millisecondsSinceEpoch),
    ));
    return model.toEntity();
  }

  @override
  Future<Business> updateBusiness(Business business) async {
    final model = BusinessModel.fromEntity(business);
    final updated = BusinessModel(
      id: model.id,
      name: model.name,
      logoPath: model.logoPath,
      address: model.address,
      phone: model.phone,
      email: model.email,
      taxNumber: model.taxNumber,
      currency: model.currency,
      currencySymbol: model.currencySymbol,
      defaultTaxRate: model.defaultTaxRate,
      invoicePrefix: model.invoicePrefix,
      estimatePrefix: model.estimatePrefix,
      purchaseOrderPrefix: model.purchaseOrderPrefix,
      creditNotePrefix: model.creditNotePrefix,
      expensePrefix: model.expensePrefix,
      notes: model.notes,
      dateFormat: model.dateFormat,
      numberFormat: model.numberFormat,
      themeMode: model.themeMode,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: model.deletedAt,
    );
    await (_db.businesses.update()
      ..where((t) => t.id.equals(updated.id))).write(BusinessesCompanion(
        name: Value(updated.name),
        logoPath: Value(updated.logoPath),
        address: Value(updated.address),
        phone: Value(updated.phone),
        email: Value(updated.email),
        taxNumber: Value(updated.taxNumber),
        currency: Value(updated.currency),
        currencySymbol: Value(updated.currencySymbol),
        defaultTaxRate: Value(updated.defaultTaxRate),
        invoicePrefix: Value(updated.invoicePrefix),
        estimatePrefix: Value(updated.estimatePrefix),
        purchaseOrderPrefix: Value(updated.purchaseOrderPrefix),
        creditNotePrefix: Value(updated.creditNotePrefix),
        expensePrefix: Value(updated.expensePrefix),
        notes: Value(updated.notes),
        dateFormat: Value(updated.dateFormat),
        numberFormat: Value(updated.numberFormat),
        themeMode: Value(updated.themeMode),
        updatedAt: Value(updated.updatedAt.millisecondsSinceEpoch),
        deletedAt: Value(updated.deletedAt?.millisecondsSinceEpoch),
      ));
    return updated.toEntity();
  }

  @override
  Future<void> deleteBusiness(String id) async {
    await (_db.businesses.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> restoreBusiness(String id) async {
    // Implementation for restoring soft-deleted business
  }

  @override
  Future<Business?> getActiveBusiness() async {
    return _activeBusiness;
  }

  @override
  Future<void> setActiveBusiness(String id) async {
    _activeBusiness = await getBusinessById(id);
  }

  Map<String, dynamic> _rowToMap(BusinessesData row) {
    return {
      'id': row.id,
      'name': row.name,
      'logo_path': row.logoPath,
      'address': row.address,
      'phone': row.phone,
      'email': row.email,
      'tax_number': row.taxNumber,
      'currency': row.currency,
      'currency_symbol': row.currencySymbol,
      'default_tax_rate': row.defaultTaxRate,
      'invoice_prefix': row.invoicePrefix,
      'estimate_prefix': row.estimatePrefix,
      'purchase_order_prefix': row.purchaseOrderPrefix,
      'credit_note_prefix': row.creditNotePrefix,
      'expense_prefix': row.expensePrefix,
      'notes': row.notes,
      'date_format': row.dateFormat,
      'number_format': row.numberFormat,
      'theme_mode': row.themeMode,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'deleted_at': row.deletedAt,
    };
  }
}
