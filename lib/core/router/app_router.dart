import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/presentation/pages/dashboard/dashboard_page.dart';
import 'package:invoice_pro/presentation/pages/customers/customers_page.dart';
import 'package:invoice_pro/presentation/pages/customers/customer_detail_page.dart';
import 'package:invoice_pro/presentation/pages/products/products_page.dart';
import 'package:invoice_pro/presentation/pages/products/product_detail_page.dart';
import 'package:invoice_pro/presentation/pages/invoices/invoices_page.dart';
import 'package:invoice_pro/presentation/pages/invoices/invoice_detail_page.dart';
import 'package:invoice_pro/presentation/pages/invoices/invoice_form_page.dart';
import 'package:invoice_pro/presentation/pages/estimates/estimates_page.dart';
import 'package:invoice_pro/presentation/pages/estimates/estimate_form_page.dart';
import 'package:invoice_pro/presentation/pages/estimates/estimate_detail_page.dart';
import 'package:invoice_pro/presentation/pages/payments/payments_page.dart';
import 'package:invoice_pro/presentation/pages/expenses/expenses_page.dart';
import 'package:invoice_pro/presentation/pages/reports/reports_page.dart';
import 'package:invoice_pro/presentation/pages/settings/settings_page.dart';
import 'package:invoice_pro/presentation/pages/settings/business_settings_page.dart';
import 'package:invoice_pro/presentation/pages/settings/security_settings_page.dart';
import 'package:invoice_pro/presentation/pages/settings/tax_rates_page.dart';
import 'package:invoice_pro/presentation/pages/settings/currencies_page.dart';
import 'package:invoice_pro/presentation/pages/search/search_page.dart';
import 'package:invoice_pro/presentation/pages/backup/backup_page.dart';
import 'package:invoice_pro/presentation/pages/credit_notes/credit_notes_page.dart';
import 'package:invoice_pro/presentation/pages/suppliers/suppliers_page.dart';
import 'package:invoice_pro/presentation/pages/recycle_bin/recycle_bin_page.dart';
import 'package:invoice_pro/presentation/pages/audit_logs/audit_logs_page.dart';
import 'package:invoice_pro/presentation/pages/purchase_orders/purchase_orders_page.dart';
import 'package:invoice_pro/presentation/pages/settings/recurring_invoices_page.dart';
import 'package:invoice_pro/presentation/widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/customers',
          name: 'customers',
          builder: (context, state) => const CustomersPage(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'customerDetail',
              builder: (context, state) => CustomerDetailPage(
                customerId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/products',
          name: 'products',
          builder: (context, state) => const ProductsPage(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'productDetail',
              builder: (context, state) => ProductDetailPage(
                productId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/invoices',
          name: 'invoices',
          builder: (context, state) => const InvoicesPage(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'invoiceCreate',
              builder: (context, state) => const InvoiceFormPage(),
            ),
            GoRoute(
              path: ':id',
              name: 'invoiceDetail',
              builder: (context, state) => InvoiceDetailPage(
                invoiceId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: ':id/edit',
              name: 'invoiceEdit',
              builder: (context, state) => InvoiceFormPage(
                invoiceId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/estimates',
          name: 'estimates',
          builder: (context, state) => const EstimatesPage(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'estimateCreate',
              builder: (context, state) => const EstimateFormPage(),
            ),
            GoRoute(
              path: ':id',
              name: 'estimateDetail',
              builder: (context, state) => EstimateDetailPage(
                estimateId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: ':id/edit',
              name: 'estimateEdit',
              builder: (context, state) => EstimateFormPage(
                estimateId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/payments',
          name: 'payments',
          builder: (context, state) => const PaymentsPage(),
        ),
        GoRoute(
          path: '/expenses',
          name: 'expenses',
          builder: (context, state) => const ExpensesPage(),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
          routes: [
            GoRoute(
              path: 'business',
              name: 'settingsBusiness',
              builder: (context, state) => const BusinessSettingsPage(),
            ),
            GoRoute(
              path: 'security',
              name: 'settingsSecurity',
              builder: (context, state) => const SecuritySettingsPage(),
            ),
            GoRoute(
              path: 'taxes',
              name: 'settingsTaxes',
              builder: (context, state) => const TaxRatesPage(),
            ),
            GoRoute(
              path: 'currencies',
              name: 'settingsCurrencies',
              builder: (context, state) => const CurrenciesPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: '/backup',
          name: 'backup',
          builder: (context, state) => const BackupPage(),
        ),
        GoRoute(
          path: '/credit-notes',
          name: 'creditNotes',
          builder: (context, state) => const CreditNotesPage(),
        ),
        GoRoute(
          path: '/suppliers',
          name: 'suppliers',
          builder: (context, state) => const SuppliersPage(),
        ),
        GoRoute(
          path: '/recycle-bin',
          name: 'recycleBin',
          builder: (context, state) => const RecycleBinPage(),
        ),
        GoRoute(
          path: '/audit-logs',
          name: 'auditLogs',
          builder: (context, state) => const AuditLogsPage(),
        ),
        GoRoute(
          path: '/purchase-orders',
          name: 'purchaseOrders',
          builder: (context, state) => const PurchaseOrdersPage(),
        ),
        GoRoute(
          path: '/recurring-invoices',
          name: 'recurringInvoices',
          builder: (context, state) => const RecurringInvoicesPage(),
        ),
      ],
    ),
  ],
);
