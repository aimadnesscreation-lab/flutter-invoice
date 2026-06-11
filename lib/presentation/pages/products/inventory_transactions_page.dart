import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:invoice_pro/core/di/injection_container.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/domain/entities/product.dart' as domain;

class InventoryTransactionsPage extends ConsumerWidget {
  final domain.Product product;

  const InventoryTransactionsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = sl<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${product.name} - Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTransactionForm(context, ref, db, product, type: 'stock_in'),
            tooltip: 'Stock In',
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => _showTransactionForm(context, ref, db, product, type: 'stock_out'),
            tooltip: 'Stock Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stock summary card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Stock', style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          '${product.quantity.toInt()} ${product.unit}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: product.isLowStock ? Colors.orange : Colors.green,
                          ),
                        ),
                        if (product.isLowStock)
                          Text('Low stock (reorder at ${product.reorderLevel.toInt()})',
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Inventory Value', style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        Helpers.formatCurrency(product.inventoryValue),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Transaction history
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Transaction History', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: FutureBuilder<List<InventoryTransaction>>(
              future: () async {
                final query = db.select(db.inventoryTransactions)
                  ..where((t) => t.productId.equals(product.id))
                  ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
                return await query.get();
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey.withAlpha(100)),
                        const SizedBox(height: 8),
                        Text('No transactions yet', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) => _buildTransactionCard(context, transactions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, InventoryTransaction tx) {
    final isIn = tx.type == 'stock_in';
    final isAdj = tx.type == 'adjustment';
    final color = isIn ? Colors.green : (isAdj ? Colors.orange : Colors.red);
    final icon = isIn ? Icons.add_circle_outline : (isAdj ? Icons.tune : Icons.remove_circle_outline);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(tx.type.replaceAll('_', ' ').toUpperCase()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Qty: ${tx.quantity >= 0 ? "+${tx.quantity.toInt()}" : tx.quantity.toInt().toString()}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            if (tx.reason != null) Text('Reason: ${tx.reason}'),
            Text(Helpers.formatDateTime(DateTime.fromMillisecondsSinceEpoch(tx.createdAt))),
          ],
        ),
      ),
    );
  }

  void _showTransactionForm(BuildContext context, WidgetRef ref, AppDatabase db, domain.Product product,
      {required String type}) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    final costController = TextEditingController(text: product.costPrice.toString());
    final isStockIn = type == 'stock_in';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isStockIn ? 'Stock In' : 'Stock Out', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              decoration: InputDecoration(
                labelText: 'Quantity *',
                prefixIcon: const Icon(Icons.numbers),
                helperText: isStockIn
                    ? 'Add to stock (${product.quantity.toInt()})'
                    : 'Remove from stock (${product.quantity.toInt()})',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            if (isStockIn)
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Unit Cost', prefixIcon: Icon(Icons.money)),
                keyboardType: TextInputType.number,
              ),
            if (isStockIn) const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                prefixIcon: const Icon(Icons.notes),
                hintText: isStockIn ? 'e.g. Purchase, Return' : 'e.g. Sale, Damage',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final qty = double.tryParse(qtyController.text);
                  if (qty == null || qty <= 0) return;
                  final businessId = ref.read(activeBusinessProvider)?.id ?? 'default';
                  final now = DateTime.now().millisecondsSinceEpoch;

                  final double insertQty = isStockIn ? qty : -qty;
                  final unitCost = isStockIn ? (double.tryParse(costController.text) ?? product.costPrice) : null;
                  final reason = reasonController.text.trim().isEmpty ? null : reasonController.text.trim();

                  await db.into(db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
                    id: Uuid().v4(),
                    businessId: businessId,
                    productId: product.id,
                    type: type,
                    quantity: insertQty,
                    unitCost: unitCost != null ? Value(unitCost) : const Value.absent(),
                    reason: reason != null ? Value(reason) : const Value.absent(),
                    createdAt: now,
                  ));

                  // Update product quantity
                  final newQty = isStockIn
                      ? product.quantity + qty
                      : (product.quantity - qty).clamp(0, double.infinity).toDouble();
                  await ref.read(productRepositoryProvider).updateProduct(product.copyWith(
                    quantity: newQty,
                    costPrice: isStockIn ? (double.tryParse(costController.text) ?? product.costPrice) : product.costPrice,
                    updatedAt: DateTime.now(),
                  ));

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${isStockIn ? "Added" : "Removed"} ${qty.toInt()} ${product.unit}')),
                    );
                  }
                },
                child: Text(isStockIn ? 'Add Stock' : 'Remove Stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
