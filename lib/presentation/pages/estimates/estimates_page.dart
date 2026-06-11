import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/estimate.dart';
import 'package:invoice_pro/presentation/widgets/shimmer_loading.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';

class EstimatesPage extends ConsumerStatefulWidget {
  const EstimatesPage({super.key});

  @override
  ConsumerState<EstimatesPage> createState() => _EstimatesPageState();
}

class _EstimatesPageState extends ConsumerState<EstimatesPage> {
  String _statusFilter = '';

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final estimatesAsync = ref.watch(estimatesProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimates'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _statusFilter = value),
            initialValue: _statusFilter,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: '',
                checked: _statusFilter == '',
                child: const Text('All'),
              ),
              CheckedPopupMenuItem(
                value: 'draft',
                checked: _statusFilter == 'draft',
                child: const Text('Draft'),
              ),
              CheckedPopupMenuItem(
                value: 'sent',
                checked: _statusFilter == 'sent',
                child: const Text('Sent'),
              ),
              CheckedPopupMenuItem(
                value: 'approved',
                checked: _statusFilter == 'approved',
                child: const Text('Approved'),
              ),
              CheckedPopupMenuItem(
                value: 'rejected',
                checked: _statusFilter == 'rejected',
                child: const Text('Rejected'),
              ),
            ],
          ),
        ],
      ),
      body: estimatesAsync.when(
        data: (estimates) {
          final filtered = _statusFilter.isEmpty
              ? estimates
              : estimates.where((e) => e.status == _statusFilter).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    filtered.isEmpty && _statusFilter.isNotEmpty
                        ? 'No $_statusFilter estimates'
                        : 'No estimates yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(estimatesProvider(businessId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildEstimateCard(context, filtered[index]),
            ),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/estimates/create');
          ref.invalidate(estimatesProvider(businessId));
        },
        icon: const Icon(Icons.add),
        label: const Text('New Estimate'),
      ),
    );
  }

  Widget _buildEstimateCard(BuildContext context, Estimate estimate) {
    final isOverdue = estimate.expiryDate.isBefore(DateTime.now()) && estimate.status != 'approved' && estimate.status != 'rejected';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          await context.push('/estimates/${estimate.id}');
          ref.invalidate(estimatesProvider(ref.read(activeBusinessProvider)?.id ?? 'default'));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red
                      : estimate.status == 'approved'
                          ? Colors.green
                          : estimate.status == 'rejected'
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(estimate.estimateNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        StatusBadge(status: estimate.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estimate.customerName ?? 'N/A',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      'Est: ${Helpers.formatDate(estimate.estimateDate)} · Exp: ${Helpers.formatDate(estimate.expiryDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Amount & actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Helpers.formatCurrency(estimate.grandTotal, symbol: estimate.currencySymbol),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (estimate.convertedInvoiceId != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade400),
                        const SizedBox(width: 4),
                        Text('Converted', style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
