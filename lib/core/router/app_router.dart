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
import 'package:invoice_pro/presentation/pages/payments/payments_page.dart';
import 'package:invoice_pro/presentation/pages/expenses/expenses_page.dart';
import 'package:invoice_pro/presentation/pages/reports/reports_page.dart';
import 'package:invoice_pro/presentation/pages/settings/settings_page.dart';
import 'package:invoice_pro/presentation/pages/search/search_page.dart';
import 'package:invoice_pro/presentation/pages/backup/backup_page.dart';
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
      ],
    ),
  ],
);
