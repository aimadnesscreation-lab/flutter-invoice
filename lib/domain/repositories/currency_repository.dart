import 'package:invoice_pro/domain/entities/currency_entity.dart';

abstract class CurrencyRepository {
  Future<List<CurrencyEntity>> getAllCurrencies(String businessId);
  Future<CurrencyEntity?> getDefaultCurrency(String businessId);
  Future<CurrencyEntity> createCurrency(CurrencyEntity currency);
  Future<CurrencyEntity> updateCurrency(CurrencyEntity currency);
  Future<void> deleteCurrency(String id);
}
