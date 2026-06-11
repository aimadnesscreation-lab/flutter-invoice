import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:invoice_pro/core/di/providers.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final statsAsync = ref.watch(dashboardStatsProvider(businessId));
    final expensesAsync = ref.watch(expensesProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue vs Expenses
            statsAsync.when(
              data: (stats) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Revenue vs Expenses', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: ((stats['yearly_revenue'] as double?) ?? 1000) * 1.2,
                            barGroups: [
                              BarChartGroupData(x: 0, barRods: [
                                BarChartRodData(toY: (stats['total_revenue'] as double?) ?? 0, color: Colors.green, width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                              ]),
                              BarChartGroupData(x: 1, barRods: [
                                BarChartRodData(toY: (stats['total_expenses'] as double?) ?? 0, color: Colors.red, width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                              ]),
                              BarChartGroupData(x: 2, barRods: [
                                BarChartRodData(toY: (stats['profit'] as double?) ?? 0, color: Colors.blue, width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                              ]),
                            ],
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                                const labels = ['Revenue', 'Expenses', 'Profit'];
                                if (value.toInt() >= labels.length) return const SizedBox();
                                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 11)));
                              })),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Expense by Category
            expensesAsync.when(
              data: (expenses) {
                final categoryTotals = <String, double>{};
                for (final e in expenses) {
                  categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
                }

                if (categoryTotals.isEmpty) return const SizedBox();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expenses by Category', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        ...categoryTotals.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  Text('\$${entry.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: entry.value / categoryTotals.values.fold(0.0, (a, b) => a + b),
                                  backgroundColor: Colors.grey.withAlpha(30),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
