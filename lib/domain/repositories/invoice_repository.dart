import 'package:invoice_pro/domain/entities/invoice.dart';

abstract class InvoiceRepository {
  Future<List<Invoice>> getAllInvoices(String businessId, {String? status, String? searchQuery, int page = 1, int pageSize = 20});
  Future<Invoice?> getInvoiceById(String id);
  Future<Invoice> createInvoice(Invoice invoice, List<InvoiceItem> items);
  Future<Invoice> updateInvoice(Invoice invoice, List<InvoiceItem> items);
  Future<void> deleteInvoice(String id);
  Future<void> restoreInvoice(String id);
  Future<String> generateInvoiceNumber(String businessId, String prefix);
  Future<Map<String, dynamic>> getInvoiceStats(String businessId);
  Future<double> getTotalRevenue(String businessId);
  Future<double> getMonthlyRevenue(String businessId);
  Future<double> getYearlyRevenue(String businessId);
  Future<List<Invoice>> getRecentInvoices(String businessId, {int limit = 10});
  Future<List<Invoice>> getOverdueInvoices(String businessId);
  Future<List<Invoice>> getRecurringInvoices(String businessId);
  Future<void> generateRecurringInvoices();
  Future<List<Map<String, dynamic>>> getRevenueChartData(String businessId, {String period = 'monthly'});
}
