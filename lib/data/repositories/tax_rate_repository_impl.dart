import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/domain/entities/tax_rate.dart' as domain;
import 'package:invoice_pro/domain/repositories/tax_rate_repository.dart';

class TaxRateRepositoryImpl implements TaxRateRepository {
  final AppDatabase _db;

  TaxRateRepositoryImpl(this._db);

  @override
  Future<List<domain.TaxRate>> getAllTaxRates(String businessId) async {
    final rows = await (_db.taxRates.select()
      ..where((t) => t.businessId.equals(businessId))).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<domain.TaxRate?> getTaxRateById(String id) async {
    final row = await (_db.taxRates.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<domain.TaxRate> createTaxRate(domain.TaxRate taxRate) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await _db.into(_db.taxRates).insert(TaxRatesCompanion.insert(
      id: id,
      businessId: taxRate.businessId,
      name: taxRate.name,
      type: taxRate.type,
      rate: taxRate.rate,
      isDefault: Value(taxRate.isDefault),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    ));
    return taxRate.copyWith(id: id, createdAt: now, updatedAt: now);
  }

  @override
  Future<domain.TaxRate> updateTaxRate(domain.TaxRate taxRate) async {
    final now = DateTime.now();
    await (_db.taxRates.update()
      ..where((t) => t.id.equals(taxRate.id))).write(TaxRatesCompanion(
        name: Value(taxRate.name),
        type: Value(taxRate.type),
        rate: Value(taxRate.rate),
        isDefault: Value(taxRate.isDefault),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ));
    return taxRate.copyWith(updatedAt: now);
  }

  @override
  Future<void> deleteTaxRate(String id) async {
    await (_db.taxRates.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<domain.TaxRate?> getDefaultTaxRate(String businessId) async {
    final rows = await (_db.taxRates.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.isDefault.equals(true))).get();
    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  domain.TaxRate _toEntity(TaxRate row) {
    return domain.TaxRate(
      id: row.id,
      businessId: row.businessId,
      name: row.name,
      type: row.type,
      rate: row.rate,
      isDefault: row.isDefault,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
