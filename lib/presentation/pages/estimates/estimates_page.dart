import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/estimate.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';

class EstimatesPage extends ConsumerWidget {
  const EstimatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimatesAsync = ref.watch(estimatesProvider('default'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimates'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {},
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'draft', child: Text('Draft')),
              PopupMenuItem(value: 'sent', child: Text('Sent')),
              PopupMenuItem(value: 'approved', child: Text('Approved')),
              PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: estimatesAsync.when(
        data: (estimates) {
          if (estimates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('No estimates yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: estimates.length,
            itemBuilder: (context, index) => _buildEstimateCard(context, estimates[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New Estimate'),
      ),
    );
  }

  Widget _buildEstimateCard(BuildContext context, Estimate estimate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: StatusBadge(status: estimate.status),
        title: Text(estimate.estimateNumber),
        subtitle: Text(
          '${estimate.customerName ?? "N/A"} · ${Helpers.formatDate(estimate.estimateDate)} · Exp: ${Helpers.formatDate(estimate.expiryDate)}',
        ),
        trailing: Text(
          Helpers.formatCurrency(estimate.grandTotal, symbol: estimate.currencySymbol),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () {},
      ),
    );
  }
}
