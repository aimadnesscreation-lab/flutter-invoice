import 'package:get_it/get_it.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/repositories/business_repository_impl.dart';
import 'package:invoice_pro/data/repositories/customer_repository_impl.dart';
import 'package:invoice_pro/data/repositories/product_repository_impl.dart';
import 'package:invoice_pro/data/repositories/invoice_repository_impl.dart';
import 'package:invoice_pro/data/repositories/payment_repository_impl.dart';
import 'package:invoice_pro/data/repositories/expense_repository_impl.dart';
import 'package:invoice_pro/data/repositories/estimate_repository_impl.dart';
import 'package:invoice_pro/data/repositories/credit_note_repository_impl.dart';
import 'package:invoice_pro/data/repositories/supplier_repository_impl.dart';
import 'package:invoice_pro/data/repositories/tax_rate_repository_impl.dart';
import 'package:invoice_pro/data/repositories/currency_repository_impl.dart';
import 'package:invoice_pro/data/repositories/settings_repository_impl.dart';
import 'package:invoice_pro/domain/repositories/business_repository.dart';
import 'package:invoice_pro/domain/repositories/customer_repository.dart';
import 'package:invoice_pro/domain/repositories/product_repository.dart';
import 'package:invoice_pro/domain/repositories/invoice_repository.dart';
import 'package:invoice_pro/domain/repositories/payment_repository.dart';
import 'package:invoice_pro/domain/repositories/expense_repository.dart';
import 'package:invoice_pro/domain/repositories/estimate_repository.dart';
import 'package:invoice_pro/domain/repositories/credit_note_repository.dart';
import 'package:invoice_pro/domain/repositories/supplier_repository.dart';
import 'package:invoice_pro/domain/repositories/tax_rate_repository.dart';
import 'package:invoice_pro/domain/repositories/currency_repository.dart';
import 'package:invoice_pro/domain/repositories/settings_repository.dart';
import 'package:invoice_pro/services/pdf_service.dart';
import 'package:invoice_pro/services/backup_service.dart';
import 'package:invoice_pro/services/security_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Services
  final securityService = SecurityService();
  sl.registerLazySingleton<SecurityService>(() => securityService);
  sl.registerLazySingleton<PdfService>(() => PdfService());

  // Database
  final dbKey = await securityService.getDatabaseKey();
  final database = AppDatabase(dbKey);
  sl.registerLazySingleton<AppDatabase>(() => database);

  sl.registerLazySingleton<BackupService>(() => BackupService(sl<AppDatabase>()));

  // Repositories
  sl.registerLazySingleton<BusinessRepository>(() => BusinessRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<InvoiceRepository>(() => InvoiceRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<ExpenseRepository>(() => ExpenseRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<EstimateRepository>(() => EstimateRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<CreditNoteRepository>(() => CreditNoteRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<SupplierRepository>(() => SupplierRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<TaxRateRepository>(() => TaxRateRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<CurrencyRepository>(() => CurrencyRepositoryImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl<AppDatabase>()));
}
