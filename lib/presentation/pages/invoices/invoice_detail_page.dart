import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';

class InvoiceDetailPage extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final invoicesAsync = ref.watch(invoicesProvider(businessId));

    return invoicesAsync.when(
      data: (invoices) {
        final invoice = invoices.where((inv) => inv.id == invoiceId).firstOrNull;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice')),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(invoice.invoiceNumber),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () {},
                tooltip: 'Export PDF',
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () {},
                tooltip: 'Print',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      context.go('/invoices/${invoice.id}/edit');
                    case 'duplicate':
                      break;
                    case 'delete':
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                  const PopupMenuItem(value: 'duplicate', child: ListTile(leading: Icon(Icons.copy), title: Text('Duplicate'))),
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
                            StatusBadge(status: invoice.status),
                            Text(
                              Helpers.formatCurrency(invoice.grandTotal, symbol: invoice.currencySymbol),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (invoice.balanceDue > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(Helpers.formatCurrency(invoice.balanceDue, symbol: invoice.currencySymbol),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
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
                        Text(invoice.customerName ?? 'N/A', style: const TextStyle(fontSize: 16)),

                        if (invoice.isPurchaseOrder) ...[
                          const SizedBox(height: 8),
                          Text('Supplier: ${invoice.supplierName ?? "N/A"}'),
                        ],

                        const Divider(),
                        _buildInfoRow('Invoice Date', Helpers.formatDate(invoice.invoiceDate)),
                        _buildInfoRow('Due Date', Helpers.formatDate(invoice.dueDate)),
                        _buildInfoRow('Status', invoice.status.toUpperCase()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Line Items
                Text('Items', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...invoice.items.map((item) => Card(
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
                              if (item.taxPercent > 0) Text('Tax: ${item.taxPercent}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                        _buildTotalRow('Subtotal', Helpers.formatCurrency(invoice.subtotal)),
                        if (invoice.discountAmount > 0) _buildTotalRow('Discount', Helpers.formatCurrency(invoice.discountAmount)),
                        _buildTotalRow('Tax', Helpers.formatCurrency(invoice.taxAmount)),
                        const Divider(),
                        _buildTotalRow('Grand Total', Helpers.formatCurrency(invoice.grandTotal), bold: true),
                        if (invoice.paidAmount > 0) _buildTotalRow('Paid', Helpers.formatCurrency(invoice.paidAmount)),
                        if (invoice.balanceDue > 0) _buildTotalRow('Balance Due', Helpers.formatCurrency(invoice.balanceDue), bold: true, color: Colors.red),
                      ],
                    ),
                  ),
                ),

                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(invoice.notes!),
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
