import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/invoice.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';

class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});

  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Draft'),
            Tab(text: 'Sent'),
            Tab(text: 'Paid'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoiceList(null),
          _buildInvoiceList('draft'),
          _buildInvoiceList('sent'),
          _buildInvoiceList('paid'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/invoices/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildInvoiceList(String? status) {
    final invoicesAsync = ref.watch(invoicesProvider('default'));

    return invoicesAsync.when(
      data: (invoices) {
        var filtered = invoices;
        if (status != null) {
          filtered = invoices.where((inv) => inv.status == status).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                const SizedBox(height: 16),
                const Text('No invoices found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildInvoiceCard(context, filtered[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: StatusBadge(status: invoice.status),
        title: Text(invoice.invoiceNumber),
        subtitle: Text(
          '${invoice.customerName ?? "N/A"} · ${Helpers.formatDate(invoice.invoiceDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Helpers.formatCurrency(invoice.grandTotal, symbol: invoice.currencySymbol),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (invoice.balanceDue > 0)
              Text(
                'Due: ${Helpers.formatCurrency(invoice.balanceDue, symbol: invoice.currencySymbol)}',
                style: TextStyle(fontSize: 11, color: invoice.balanceDue > 0 ? Colors.red : Colors.green),
              ),
          ],
        ),
        onTap: () => context.go('/invoices/${invoice.id}'),
      ),
    );
  }
}
