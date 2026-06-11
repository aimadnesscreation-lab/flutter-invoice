import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/invoice.dart';
import 'package:invoice_pro/presentation/widgets/shimmer_loading.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';

class RecurringInvoicesPage extends ConsumerStatefulWidget {
  const RecurringInvoicesPage({super.key});

  @override
  ConsumerState<RecurringInvoicesPage> createState() => _RecurringInvoicesPageState();
}

class _RecurringInvoicesPageState extends ConsumerState<RecurringInvoicesPage> {
  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final invoicesAsync = ref.watch(invoicesProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await ref.read(invoiceRepositoryProvider).generateRecurringInvoices();
                ref.invalidate(invoicesProvider(businessId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recurring invoices generated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            tooltip: 'Generate Due Invoices',
          ),
        ],
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          final recurring = invoices.where((inv) => inv.isRecurring).toList();
          if (recurring.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('No recurring invoices'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.go('/invoices/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Invoice with Recurring'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recurring.length,
            itemBuilder: (context, index) => _buildCard(context, recurring[index]),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Recurring'),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Invoice inv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(inv.invoiceNumber),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${inv.customerName ?? "N/A"} · ${inv.recurringInterval ?? "N/A"}'),
            if (inv.recurringNextDate != null)
              Text('Next: ${Helpers.formatDate(inv.recurringNextDate!)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Helpers.formatCurrency(inv.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
            StatusBadge(status: inv.status),
          ],
        ),
        onTap: () => context.go('/invoices/${inv.id}'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    context.go('/invoices/create');
  }
}
