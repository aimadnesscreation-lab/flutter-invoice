import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/injection_container.dart';
import 'package:invoice_pro/domain/entities/business.dart';
import 'package:invoice_pro/domain/entities/customer.dart';
import 'package:invoice_pro/domain/entities/product.dart';
import 'package:invoice_pro/domain/entities/invoice.dart';
import 'package:invoice_pro/domain/entities/payment.dart';
import 'package:invoice_pro/domain/entities/expense.dart';
import 'package:invoice_pro/domain/entities/estimate.dart';
import 'package:invoice_pro/domain/entities/supplier.dart';
import 'package:invoice_pro/domain/repositories/audit_log_repository.dart';
import 'package:invoice_pro/domain/repositories/trash_repository.dart';
import 'package:invoice_pro/domain/repositories/business_repository.dart';
import 'package:invoice_pro/domain/repositories/customer_repository.dart';
import 'package:invoice_pro/domain/repositories/product_repository.dart';
import 'package:invoice_pro/domain/repositories/invoice_repository.dart';
import 'package:invoice_pro/domain/repositories/payment_repository.dart';
import 'package:invoice_pro/domain/repositories/expense_repository.dart';
import 'package:invoice_pro/domain/repositories/estimate_repository.dart';
import 'package:invoice_pro/domain/repositories/supplier_repository.dart';
import 'package:invoice_pro/domain/repositories/tax_rate_repository.dart';
import 'package:invoice_pro/domain/repositories/currency_repository.dart';
import 'package:invoice_pro/domain/repositories/credit_note_repository.dart';
import 'package:invoice_pro/domain/repositories/settings_repository.dart';
import 'package:invoice_pro/services/security_service.dart';

// Repository providers
final businessRepositoryProvider = Provider<BusinessRepository>((ref) => sl());
final customerRepositoryProvider = Provider<CustomerRepository>((ref) => sl());
final productRepositoryProvider = Provider<ProductRepository>((ref) => sl());
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) => sl());
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => sl());
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) => sl());
final estimateRepositoryProvider = Provider<EstimateRepository>((ref) => sl());
final supplierRepositoryProvider = Provider<SupplierRepository>((ref) => sl());
final taxRateRepositoryProvider = Provider<TaxRateRepository>((ref) => sl());
final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) => sl());
final creditNoteRepositoryProvider = Provider<CreditNoteRepository>((ref) => sl());
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => sl());
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) => sl());
final trashRepositoryProvider = Provider<TrashRepository>((ref) => sl());

// Service providers
final securityServiceProvider = Provider<SecurityService>((ref) => sl());

// Business providers
final activeBusinessProvider = StateNotifierProvider<ActiveBusinessNotifier, Business?>((ref) {
  return ActiveBusinessNotifier(ref.watch(businessRepositoryProvider));
});

class ActiveBusinessNotifier extends StateNotifier<Business?> {
  final BusinessRepository _repository;

  ActiveBusinessNotifier(this._repository) : super(null);

  Future<void> setActiveBusiness(String id) async {
    await _repository.setActiveBusiness(id);
    state = await _repository.getBusinessById(id);
  }

  Future<void> loadActiveBusiness() async {
    state = await _repository.getActiveBusiness();
  }
}

final businessesProvider = FutureProvider<List<Business>>((ref) async {
  return ref.watch(businessRepositoryProvider).getAllBusinesses();
});

// Customer providers
final customersProvider = FutureProvider.family<List<Customer>, String>((ref, businessId) async {
  return ref.watch(customerRepositoryProvider).getAllCustomers(businessId);
});

final customerSearchProvider = FutureProvider.family<List<Customer>, Map<String, dynamic>>((ref, params) async {
  return ref.watch(customerRepositoryProvider).getAllCustomers(
    params['businessId'] as String,
    searchQuery: params['query'] as String?,
  );
});

// Product providers
final productsProvider = FutureProvider.family<List<Product>, String>((ref, businessId) async {
  return ref.watch(productRepositoryProvider).getAllProducts(businessId);
});

final lowStockProductsProvider = FutureProvider.family<List<Product>, String>((ref, businessId) async {
  return ref.watch(productRepositoryProvider).getLowStockProducts(businessId);
});

// Invoice providers
final invoicesProvider = FutureProvider.family<List<Invoice>, String>((ref, businessId) async {
  return ref.watch(invoiceRepositoryProvider).getAllInvoices(businessId);
});

final recentInvoicesProvider = FutureProvider.family<List<Invoice>, String>((ref, businessId) async {
  return ref.watch(invoiceRepositoryProvider).getRecentInvoices(businessId);
});

final overdueInvoicesProvider = FutureProvider.family<List<Invoice>, String>((ref, businessId) async {
  return ref.watch(invoiceRepositoryProvider).getOverdueInvoices(businessId);
});

// Payment providers
final paymentsProvider = FutureProvider.family<List<Payment>, String>((ref, businessId) async {
  return ref.watch(paymentRepositoryProvider).getAllPayments(businessId);
});

// Expense providers
final expensesProvider = FutureProvider.family<List<Expense>, String>((ref, businessId) async {
  return ref.watch(expenseRepositoryProvider).getAllExpenses(businessId);
});

// Estimate providers
final estimatesProvider = FutureProvider.family<List<Estimate>, String>((ref, businessId) async {
  return ref.watch(estimateRepositoryProvider).getAllEstimates(businessId);
});

// Supplier providers
final suppliersProvider = FutureProvider.family<List<Supplier>, String>((ref, businessId) async {
  return ref.watch(supplierRepositoryProvider).getAllSuppliers(businessId);
});

// Credit Note providers
final creditNotesProvider = FutureProvider.family<List<CreditNote>, String>((ref, businessId) async {
  return ref.watch(creditNoteRepositoryProvider).getAllCreditNotes(businessId);
});

// Audit Log providers
final auditLogsProvider = FutureProvider.family<List<AuditLog>, Map<String, dynamic>>((ref, params) async {
  return ref.watch(auditLogRepositoryProvider).getLogs(
    params['businessId'] as String,
    entityType: params['entityType'] as String?,
    entityId: params['entityId'] as String?,
  );
});

// Trash providers
final trashProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, businessId) async {
  return ref.watch(trashRepositoryProvider).getTrashItems(businessId);
});

// Dashboard stats provider
final dashboardStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, businessId) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final customerRepo = ref.watch(customerRepositoryProvider);
  final productRepo = ref.watch(productRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);

  final invoiceStats = await invoiceRepo.getInvoiceStats(businessId);
  final customerCount = await customerRepo.getCustomerCount(businessId);
  final productCount = await productRepo.getProductCount(businessId);
  final totalRevenue = await invoiceRepo.getTotalRevenue(businessId);
  final monthlyRevenue = await invoiceRepo.getMonthlyRevenue(businessId);
  final yearlyRevenue = await invoiceRepo.getYearlyRevenue(businessId);
  final totalExpenses = await expenseRepo.getTotalExpenses(businessId);
  final monthlyExpenses = await expenseRepo.getMonthlyExpenses(businessId);

  return {
    'total_revenue': totalRevenue,
    'monthly_revenue': monthlyRevenue,
    'yearly_revenue': yearlyRevenue,
    'pending_invoices': (invoiceStats['total'] as int) - (invoiceStats['paid'] as int),
    'paid_invoices': invoiceStats['paid'],
    'overdue_invoices': invoiceStats['overdue'],
    'total_customers': customerCount,
    'total_products': productCount,
    'total_expenses': totalExpenses,
    'monthly_expenses': monthlyExpenses,
    'profit': yearlyRevenue - totalExpenses,
  };
});
