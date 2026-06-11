import 'package:invoice_pro/domain/entities/tax_rate.dart';

abstract class TaxRateRepository {
  Future<List<TaxRate>> getAllTaxRates(String businessId);
  Future<TaxRate?> getTaxRateById(String id);
  Future<TaxRate> createTaxRate(TaxRate taxRate);
  Future<TaxRate> updateTaxRate(TaxRate taxRate);
  Future<void> deleteTaxRate(String id);
  Future<TaxRate?> getDefaultTaxRate(String businessId);
}
