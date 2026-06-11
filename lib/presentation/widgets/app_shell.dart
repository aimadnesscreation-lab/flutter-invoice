import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/customers')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/invoices')) return 3;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/customers');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/invoices');
        break;
      case 4:
        _showMoreMenu(context);
        break;
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _MoreMenuItem(
                    icon: Icons.request_quote_outlined,
                    title: 'Estimates',
                    onTap: () { context.pop(); context.go('/estimates'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.payments_outlined,
                    title: 'Payments',
                    onTap: () { context.pop(); context.go('/payments'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.money_off_outlined,
                    title: 'Expenses',
                    onTap: () { context.pop(); context.go('/expenses'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.store_outlined,
                    title: 'Suppliers',
                    onTap: () { context.pop(); context.go('/suppliers'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.request_quote_outlined,
                    title: 'Credit Notes',
                    onTap: () { context.pop(); context.go('/credit-notes'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Purchase Orders',
                    onTap: () { context.pop(); context.go('/purchase-orders'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.bar_chart_outlined,
                    title: 'Reports',
                    onTap: () { context.pop(); context.go('/reports'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.search_outlined,
                    title: 'Search',
                    onTap: () { context.pop(); context.go('/search'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.backup_outlined,
                    title: 'Backup & Restore',
                    onTap: () { context.pop(); context.go('/backup'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.history_outlined,
                    title: 'Audit Logs',
                    onTap: () { context.pop(); context.go('/audit-logs'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Recycle Bin',
                    onTap: () { context.pop(); context.go('/recycle-bin'); },
                  ),
                  _MoreMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () { context.pop(); context.go('/settings'); },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
