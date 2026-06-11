import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/invoice.dart';
import 'package:invoice_pro/domain/entities/customer.dart';
import 'package:invoice_pro/presentation/widgets/dashboard_card.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final colorScheme = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(dashboardStatsProvider(businessId));
    final recentInvoicesAsync = ref.watch(recentInvoicesProvider(businessId));
    final customersAsync = ref.watch(customersProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider(businessId));
          ref.invalidate(recentInvoicesProvider(businessId));
          ref.invalidate(customersProvider(businessId));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              statsAsync.when(
                data: (stats) => _buildStatsGrid(context, stats, colorScheme),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              const SizedBox(height: 24),

              // Revenue Chart
              statsAsync.when(
                data: (stats) => _buildRevenueChart(context, stats, colorScheme),
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),

              const SizedBox(height: 24),

              // Recent Invoices
              Text('Recent Invoices', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              recentInvoicesAsync.when(
                data: (invoices) => _buildRecentInvoices(context, invoices),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              const SizedBox(height: 24),

              // Recent Customers
              Text('Recent Customers', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              customersAsync.when(
                data: (customers) => _buildRecentCustomers(context, customers),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats, ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        DashboardCard(
          title: 'Total Revenue',
          value: Helpers.formatCurrency((stats['total_revenue'] as double?) ?? 0),
          icon: Icons.trending_up,
          color: colorScheme.primary,
        ),
        DashboardCard(
          title: 'Pending',
          value: '${stats['pending_invoices'] ?? 0}',
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        DashboardCard(
          title: 'Overdue',
          value: '${stats['overdue_invoices'] ?? 0}',
          icon: Icons.warning_amber,
          color: Colors.red,
        ),
        DashboardCard(
          title: 'Customers',
          value: '${stats['total_customers'] ?? 0}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        DashboardCard(
          title: 'Products',
          value: '${stats['total_products'] ?? 0}',
          icon: Icons.inventory_2,
          color: Colors.green,
        ),
        DashboardCard(
          title: 'Monthly Rev.',
          value: Helpers.formatCurrency((stats['monthly_revenue'] as double?) ?? 0),
          icon: Icons.calendar_month,
          color: Colors.purple,
        ),
        DashboardCard(
          title: 'Yearly Rev.',
          value: Helpers.formatCurrency((stats['yearly_revenue'] as double?) ?? 0),
          icon: Icons.calendar_view_week,
          color: Colors.teal,
        ),
        DashboardCard(
          title: 'Profit',
          value: Helpers.formatCurrency((stats['profit'] as double?) ?? 0),
          icon: Icons.account_balance,
          color: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildRevenueChart(BuildContext context, Map<String, dynamic> stats, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: ((stats['yearly_revenue'] as double? ?? 1000) * 1.2).clamp(100, double.infinity),
                  barGroups: [
                    _makeBarData(0, 'Monthly', (stats['monthly_revenue'] as double? ?? 0), colorScheme.primary),
                    _makeBarData(1, 'Yearly', (stats['yearly_revenue'] as double? ?? 0), colorScheme.secondary),
                    _makeBarData(2, 'Expenses', (stats['monthly_expenses'] as double? ?? 0), Colors.red),
                    _makeBarData(3, 'Profit', (stats['profit'] as double? ?? 0), Colors.green),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['Monthly\nRev', 'Yearly\nRev', 'Expenses', 'Profit'];
                          if (value.toInt() >= labels.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((stats['yearly_revenue'] as double?) ?? 1000).clamp(100, double.infinity) / 4,
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, String label, double value, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: value, color: color, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
    ]);
  }

  Widget _buildRecentInvoices(BuildContext context, List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('No invoices yet', style: Theme.of(context).textTheme.bodyLarge)),
        ),
      );
    }

    return Column(
      children: invoices.take(5).map((invoice) => Card(
        child: ListTile(
          leading: StatusBadge(status: invoice.status),
          title: Text(invoice.invoiceNumber),
          subtitle: Text('${invoice.customerName ?? "N/A"} - ${Helpers.formatCurrency(invoice.grandTotal, symbol: invoice.currencySymbol)}'),
          trailing: Text(Helpers.formatDate(invoice.invoiceDate), style: Theme.of(context).textTheme.bodySmall),
          onTap: () => context.go('/invoices/${invoice.id}'),
        ),
      )).toList(),
    );
  }

  Widget _buildRecentCustomers(BuildContext context, List<Customer> customers) {
    if (customers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('No customers yet', style: Theme.of(context).textTheme.bodyLarge)),
        ),
      );
    }

    return Column(
      children: customers.take(5).map((customer) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?')),
          title: Text(customer.name),
          subtitle: Text(customer.email ?? customer.phone ?? 'No contact'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/customers/${customer.id}'),
        ),
      )).toList(),
    );
  }
}
