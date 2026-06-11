import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/domain/entities/currency_entity.dart';
import 'package:invoice_pro/domain/repositories/currency_repository.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final AppDatabase _db;

  CurrencyRepositoryImpl(this._db);

  @override
  Future<List<CurrencyEntity>> getAllCurrencies(String businessId) async {
    final rows = await (_db.currencies.select()
      ..where((t) => t.businessId.equals(businessId))).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<CurrencyEntity?> getDefaultCurrency(String businessId) async {
    final rows = await (_db.currencies.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.isDefault.equals(true))).get();
    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  @override
  Future<CurrencyEntity> createCurrency(CurrencyEntity currency) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await _db.into(_db.currencies).insert(CurrenciesCompanion.insert(
      id: id,
      businessId: currency.businessId,
      code: currency.code,
      name: currency.name,
      symbol: currency.symbol,
      exchangeRate: Value(currency.exchangeRate),
      isDefault: Value(currency.isDefault),
      createdAt: now.millisecondsSinceEpoch,
    ));
    return currency.copyWith(id: id, createdAt: now);
  }

  @override
  Future<CurrencyEntity> updateCurrency(CurrencyEntity currency) async {
    await (_db.currencies.update()
      ..where((t) => t.id.equals(currency.id))).write(CurrenciesCompanion(
        code: Value(currency.code),
        name: Value(currency.name),
        symbol: Value(currency.symbol),
        exchangeRate: Value(currency.exchangeRate),
        isDefault: Value(currency.isDefault),
      ));
    return currency;
  }

  @override
  Future<void> deleteCurrency(String id) async {
    await (_db.currencies.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  CurrencyEntity _toEntity(Currency row) {
    return CurrencyEntity(
      id: row.id,
      businessId: row.businessId,
      code: row.code,
      name: row.name,
      symbol: row.symbol,
      exchangeRate: row.exchangeRate,
      isDefault: row.isDefault,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    );
  }
}
