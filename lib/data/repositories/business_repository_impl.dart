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
    final rows = await (_db.select(_db.businesses)..where((t) => t.deletedAt.isNull())).get();
    return rows.map((row) => BusinessModel.fromMap(_rowToMap(row)).toEntity()).toList();
  }

  @override
  Future<Business?> getBusinessById(String id) async {
    final row = await (_db.select(_db.businesses)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return BusinessModel.fromMap(_rowToMap(row)).toEntity();
  }

  @override
  Future<Business> createBusiness(Business business) async {
    final id = business.id.isEmpty ? const Uuid().v4() : business.id;
    final now = DateTime.now();
    final model = BusinessModel.fromEntity(business.copyWith(id: id, createdAt: now, updatedAt: now));
    
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
    ));
    return model.toEntity();
  }

  @override
  Future<Business> updateBusiness(Business business) async {
    final now = DateTime.now();
    final model = BusinessModel.fromEntity(business.copyWith(updatedAt: now));
    
    await (_db.businesses.update()..where((t) => t.id.equals(model.id))).write(BusinessesCompanion(
        name: Value(model.name),
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
        updatedAt: Value(model.updatedAt.millisecondsSinceEpoch),
        deletedAt: Value(model.deletedAt?.millisecondsSinceEpoch),
    ));
    return model.toEntity();
  }

  @override
  Future<void> deleteBusiness(String id) async {
    await (_db.businesses.update()..where((t) => t.id.equals(id))).write(
      BusinessesCompanion(deletedAt: Value(DateTime.now().millisecondsSinceEpoch))
    );
  }

  @override
  Future<void> restoreBusiness(String id) async {
    await (_db.businesses.update()..where((t) => t.id.equals(id))).write(
      const BusinessesCompanion(deletedAt: Value(null))
    );
  }

  @override
  Future<Business?> getActiveBusiness() async {
    if (_activeBusiness != null) return _activeBusiness;
    
    final setting = await (_db.select(_db.appSettings)..where((t) => t.key.equals('active_business_id'))).getSingleOrNull();
    if (setting != null) {
      _activeBusiness = await getBusinessById(setting.value);
    }
    
    if (_activeBusiness == null) {
      final all = await getAllBusinesses();
      if (all.isNotEmpty) {
        _activeBusiness = all.first;
        await setActiveBusiness(_activeBusiness!.id);
      }
    }
    
    return _activeBusiness;
  }

  @override
  Future<void> setActiveBusiness(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
      key: const Value('active_business_id'),
      value: Value(id),
      updatedAt: Value(now),
    ));
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
