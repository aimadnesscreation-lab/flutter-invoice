import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/di/injection_container.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';
import 'package:invoice_pro/services/pdf_service.dart';
import 'package:uuid/uuid.dart';

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

        final canMarkSent = invoice.status == 'draft';
        final canMarkPaid = invoice.status == 'sent' || invoice.status == 'draft' || invoice.status == 'partial';

        return Scaffold(
          appBar: AppBar(
            title: Text(invoice.invoiceNumber),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () async {
                  if (business == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No business configured')),
                    );
                    return;
                  }
                  try {
                    final pdfService = sl<PdfService>();
                    await pdfService.saveInvoicePdf(invoice, business);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF saved: invoice_${invoice.invoiceNumber}.pdf')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                tooltip: 'Export PDF',
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () async {
                  if (business == null) return;
                  try {
                    final pdfService = sl<PdfService>();
                    await pdfService.printInvoice(invoice, business);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                tooltip: 'Print',
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      context.go('/invoices/${invoice.id}/edit');
                    case 'duplicate':
                      final repo = ref.read(invoiceRepositoryProvider);
                      final newInvoiceNumber = await repo.generateInvoiceNumber(businessId, 'INV-');
                      await repo.createInvoice(invoice.copyWith(
                        id: const Uuid().v4(),
                        invoiceNumber: newInvoiceNumber,
                        status: 'draft',
                        paidAmount: 0,
                        balanceDue: invoice.grandTotal,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ), invoice.items);
                      ref.invalidate(invoicesProvider(businessId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invoice duplicated')),
                        );
                      }
                    case 'delete':
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Invoice'),
                          content: Text('Delete invoice "${invoice.invoiceNumber}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(invoiceRepositoryProvider).deleteInvoice(invoice.id);
                        ref.invalidate(invoicesProvider(businessId));
                        if (context.mounted) context.pop();
                      }
                    case 'mark_sent':
                      await _updateStatus(ref, context, invoice, 'sent');
                    case 'mark_paid':
                      await _updateStatus(ref, context, invoice, 'paid');
                    case 'mark_cancelled':
                      await _updateStatus(ref, context, invoice, 'cancelled');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                  const PopupMenuItem(value: 'duplicate', child: ListTile(leading: Icon(Icons.copy), title: Text('Duplicate'))),
                  if (canMarkSent)
                    const PopupMenuItem(value: 'mark_sent', child: ListTile(leading: Icon(Icons.send), title: Text('Mark Sent'))),
                  if (canMarkPaid)
                    const PopupMenuItem(value: 'mark_paid', child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Mark Paid'))),
                  const PopupMenuItem(value: 'mark_cancelled', child: ListTile(leading: Icon(Icons.cancel, color: Colors.orange), title: Text('Cancel'))),
                  const PopupMenuDivider(),
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
                        if (invoice.paidAmount > 0 && invoice.dueDate.isBefore(DateTime.now()))
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Overdue', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(Helpers.formatCurrency(invoice.balanceDue, symbol: invoice.currencySymbol),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Actions
                if (canMarkSent || canMarkPaid)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (canMarkSent)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateStatus(ref, context, invoice, 'sent'),
                                icon: const Icon(Icons.send, size: 18),
                                label: const Text('Mark Sent'),
                              ),
                            ),
                          if (canMarkSent && canMarkPaid) const SizedBox(width: 8),
                          if (canMarkPaid)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus(ref, context, invoice, 'paid'),
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text('Mark Paid'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (canMarkSent || canMarkPaid) const SizedBox(height: 16),

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

  Future<void> _updateStatus(WidgetRef ref, BuildContext context, Invoice invoice, String newStatus) async {
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final businessId = ref.read(activeBusinessProvider)?.id ?? 'default';
      
      Invoice updatedInvoice;
      if (newStatus == 'paid') {
        updatedInvoice = invoice.copyWith(
          status: newStatus,
          paidAmount: invoice.grandTotal,
          balanceDue: 0,
          updatedAt: DateTime.now(),
        );
      } else {
        updatedInvoice = invoice.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      await repo.updateInvoice(updatedInvoice, invoice.items);
      ref.invalidate(invoicesProvider(businessId));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice marked as $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
