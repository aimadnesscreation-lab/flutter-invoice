import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/invoice.dart';

import 'package:invoice_pro/presentation/widgets/shimmer_loading.dart';
import 'package:invoice_pro/presentation/widgets/status_badge.dart';

class PurchaseOrdersPage extends ConsumerStatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  ConsumerState<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends ConsumerState<PurchaseOrdersPage> {
  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final invoicesAsync = ref.watch(invoicesProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders')),
      body: invoicesAsync.when(
        data: (invoices) {
          final pos = invoices.where((inv) => inv.isPurchaseOrder).toList();
          if (pos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('No purchase orders'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pos.length,
            itemBuilder: (context, index) => _buildCard(context, pos[index]),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed('purchaseOrderCreate'),
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Invoice po) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_cart, color: Colors.blue),
        ),
        title: Text(po.invoiceNumber),
        subtitle: Text('${po.supplierName ?? po.customerName ?? "N/A"} · ${Helpers.formatDate(po.invoiceDate)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(status: po.status),
            const SizedBox(width: 8),
            Text(Helpers.formatCurrency(po.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () => context.goNamed('purchaseOrderEdit', pathParameters: {'id': po.id}),
      ),
    );
  }
}
