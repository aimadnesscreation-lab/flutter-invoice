import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';

class EstimateDetailPage extends ConsumerWidget {
  final String estimateId;

  const EstimateDetailPage({super.key, required this.estimateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final estimatesAsync = ref.watch(estimatesProvider(businessId));
    return estimatesAsync.when(
      data: (estimates) {
        final estimate = estimates.where((e) => e.id == estimateId).firstOrNull;
        if (estimate == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Estimate')),
            body: const Center(child: Text('Estimate not found')),
          );
        }

        final canEdit = estimate.status == 'draft';
        final canConvert = estimate.status == 'approved' || estimate.status == 'draft';
        final hasConverted = estimate.convertedInvoiceId != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(estimate.estimateNumber),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      if (canEdit) {
                        context.go('/estimates/${estimate.id}/edit');
                      }
                    case 'duplicate':
                      final repo = ref.read(estimateRepositoryProvider);
                      final prefix = business?.estimatePrefix ?? 'EST-';
                      final newNumber = await repo.generateEstimateNumber(businessId, prefix);
                      await repo.createEstimate(estimate.copyWith(
                        id: uuid_pkg.Uuid().v4(),
                        estimateNumber: newNumber,
                        status: 'draft',
                        convertedInvoiceId: null,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ), estimate.items);
                      // Use uuid instead
                      break;
                    case 'send':
                      await _updateStatus(ref, estimate, 'sent');
                    case 'approve':
                      await _updateStatus(ref, estimate, 'approved');
                    case 'reject':
                      await _updateStatus(ref, estimate, 'rejected');
                    case 'convert':
                      if (!hasConverted) {
                        final invoiceId = await ref.read(estimateRepositoryProvider).convertEstimateToInvoice(estimate.id);
                        ref.invalidate(estimatesProvider(businessId));
                        if (context.mounted && invoiceId != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Converted to invoice'),
                              action: SnackBarAction(
                                label: 'View',
                                onPressed: () => context.go('/invoices/$invoiceId'),
                              ),
                            ),
                          );
                        }
                      }
                    case 'delete':
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Estimate'),
                          content: Text('Delete "${estimate.estimateNumber}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(estimateRepositoryProvider).deleteEstimate(estimate.id);
                        ref.invalidate(estimatesProvider(businessId));
                        if (context.mounted) context.pop();
                      }
                  }
                },
                itemBuilder: (context) => [
                  if (canEdit)
                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                  const PopupMenuItem(value: 'duplicate', child: ListTile(leading: Icon(Icons.copy), title: Text('Duplicate'))),
                  if (estimate.status == 'draft')
                    const PopupMenuItem(value: 'send', child: ListTile(leading: Icon(Icons.send), title: Text('Mark Sent'))),
                  if (estimate.status == 'sent')
                    const PopupMenuItem(value: 'approve', child: ListTile(leading: Icon(Icons.thumb_up), title: Text('Approve'))),
                  if (estimate.status == 'sent')
                    const PopupMenuItem(value: 'reject', child: ListTile(leading: Icon(Icons.thumb_down), title: Text('Reject'))),
                  if (canConvert && !hasConverted)
                    const PopupMenuItem(value: 'convert', child: ListTile(leading: Icon(Icons.receipt_long), title: Text('Convert to Invoice'))),
                  if (hasConverted)
                    PopupMenuItem(
                      value: 'view_invoice',
                      child: ListTile(
                        leading: Icon(Icons.receipt_long, color: Colors.green),
                        title: const Text('View Invoice'),
                      ),
                    ),
                  const PopupMenuDivider(),
                  if (canEdit)
                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status & Totals
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(status: estimate.status),
                            Text(
                              Helpers.formatCurrency(estimate.grandTotal, symbol: estimate.currencySymbol),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (hasConverted) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text('Converted to Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (estimate.status == 'draft')
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(ref, estimate, 'sent'),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Mark Sent'),
                          ),
                        if (estimate.status == 'sent')
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(ref, estimate, 'approved'),
                            icon: const Icon(Icons.thumb_up, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          ),
                        if (canConvert && !hasConverted)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final invoiceId = await ref.read(estimateRepositoryProvider).convertEstimateToInvoice(estimate.id);
                              ref.invalidate(estimatesProvider(businessId));
                              if (context.mounted && invoiceId != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Converted to invoice'),
                                    action: SnackBarAction(
                                      label: 'View',
                                      onPressed: () => context.go('/invoices/$invoiceId'),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.receipt_long, size: 18),
                            label: const Text('Convert to Invoice'),
                          ),
                        if (hasConverted && estimate.convertedInvoiceId != null)
                          OutlinedButton.icon(
                            onPressed: () => context.go('/invoices/${estimate.convertedInvoiceId}'),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('View Invoice'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(estimate.customerName ?? 'N/A', style: const TextStyle(fontSize: 16)),
                        const Divider(),
                        _buildInfoRow('Estimate Date', Helpers.formatDate(estimate.estimateDate)),
                        _buildInfoRow('Expiry Date', Helpers.formatDate(estimate.expiryDate)),
                        _buildInfoRow('Status', estimate.status.toUpperCase()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Line Items
                Text('Items', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...estimate.items.map((item) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text('${item.quantity.toInt()} × ${Helpers.formatCurrency(item.unitPrice)}'),
                              if (item.taxPercent > 0)
                                Text('Tax: ${item.taxPercent}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Text(Helpers.formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 16),

                // Totals
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTotalRow('Subtotal', Helpers.formatCurrency(estimate.subtotal)),
                        if (estimate.discountAmount > 0) _buildTotalRow('Discount', Helpers.formatCurrency(estimate.discountAmount)),
                        _buildTotalRow('Tax', Helpers.formatCurrency(estimate.taxAmount)),
                        const Divider(),
                        _buildTotalRow('Grand Total', Helpers.formatCurrency(estimate.grandTotal), bold: true),
                      ],
                    ),
                  ),
                ),

                if (estimate.notes != null && estimate.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(estimate.notes!),
                        ],
                      ),
                    ),
                  ),
                ],

                if (estimate.termsAndConditions != null && estimate.termsAndConditions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Terms & Conditions', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(estimate.termsAndConditions!),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, estimate, String newStatus) async {
    final repo = ref.read(estimateRepositoryProvider);
    final businessId = ref.read(activeBusinessProvider)?.id ?? 'default';
    await repo.updateEstimate(estimate.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    ), estimate.items);
    ref.invalidate(estimatesProvider(businessId));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
