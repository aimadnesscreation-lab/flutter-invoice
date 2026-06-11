import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/product.dart';

class ProductDetailPage extends ConsumerWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final productsAsync = ref.watch(productsProvider(businessId));

    return productsAsync.when(
      data: (products) {
        final product = products.where((p) => p.id == productId).firstOrNull;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: const Center(child: Text('Product not found')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editProduct(context, ref, product, businessId),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteProduct(context, ref, product, businessId),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and low stock warning
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: product.isLowStock ? Colors.orange.withAlpha(30) : Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              product.isLowStock ? Icons.warning_amber : Icons.inventory_2,
                              size: 32,
                              color: product.isLowStock ? Colors.orange : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: Theme.of(context).textTheme.titleLarge),
                              Text(product.sku ?? 'No SKU', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Low stock alert
                if (product.isLowStock)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Low stock: ${product.quantity.toInt()} remaining (reorder at ${product.reorderLevel.toInt()})',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),

                // Details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRow('SKU', product.sku ?? 'N/A', Icons.tag),
                        const Divider(height: 16),
                        _buildRow('Barcode', product.barcode ?? 'N/A', Icons.qr_code),
                        const Divider(height: 16),
                        _buildRow('Cost Price', Helpers.formatCurrency(product.costPrice), Icons.shopping_cart),
                        const Divider(height: 16),
                        _buildRow('Selling Price', Helpers.formatCurrency(product.sellingPrice), Icons.attach_money),
                        const Divider(height: 16),
                        _buildRow('Stock Quantity', '${product.quantity.toInt()}', Icons.numbers),
                        const Divider(height: 16),
                        _buildRow('Reorder Level', '${product.reorderLevel.toInt()}', Icons.low_priority),
                        const Divider(height: 16),
                        _buildRow('Unit', product.unit, Icons.straighten),
                        if (product.description != null && product.description!.isNotEmpty) ...[
                          const Divider(height: 16),
                          _buildRow('Description', product.description!, Icons.description),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Profit margin
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profit & Valuation', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _buildStatRow('Profit per Unit', Helpers.formatCurrency(product.sellingPrice - product.costPrice)),
                        _buildStatRow('Margin', product.costPrice > 0 ? '${((product.sellingPrice - product.costPrice) / product.sellingPrice * 100).toStringAsFixed(1)}%' : 'N/A'),
                        _buildStatRow('Inventory Value', Helpers.formatCurrency(product.quantity * product.costPrice)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  void _editProduct(BuildContext context, WidgetRef ref, Product product, String businessId) {
    final nameController = TextEditingController(text: product.name);
    final skuController = TextEditingController(text: product.sku ?? '');
    final barcodeController = TextEditingController(text: product.barcode ?? '');
    final descriptionController = TextEditingController(text: product.description ?? '');
    final costPriceController = TextEditingController(text: product.costPrice.toString());
    final sellingPriceController = TextEditingController(text: product.sellingPrice.toString());
    final quantityController = TextEditingController(text: product.quantity.toString());
    final reorderLevelController = TextEditingController(text: product.reorderLevel.toString());
    final unitController = TextEditingController(text: product.unit);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Product', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.shopping_bag)), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU', prefixIcon: Icon(Icons.tag))),
              const SizedBox(height: 12),
              TextField(controller: barcodeController, decoration: const InputDecoration(labelText: 'Barcode', prefixIcon: Icon(Icons.qr_code))),
              const SizedBox(height: 12),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)), maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: costPriceController, decoration: const InputDecoration(labelText: 'Cost Price', prefixIcon: Icon(Icons.money)), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: sellingPriceController, decoration: const InputDecoration(labelText: 'Selling Price', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers)), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: reorderLevelController, decoration: const InputDecoration(labelText: 'Reorder Level', prefixIcon: Icon(Icons.low_priority)), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit', prefixIcon: Icon(Icons.straighten))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final repo = ref.read(productRepositoryProvider);
                    await repo.updateProduct(product.copyWith(
                      name: nameController.text.trim(),
                      sku: skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                      barcode: barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim(),
                      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                      costPrice: double.tryParse(costPriceController.text) ?? product.costPrice,
                      sellingPrice: double.tryParse(sellingPriceController.text) ?? product.sellingPrice,
                      quantity: double.tryParse(quantityController.text) ?? product.quantity,
                      reorderLevel: double.tryParse(reorderLevelController.text) ?? product.reorderLevel,
                      unit: unitController.text.trim().isEmpty ? product.unit : unitController.text.trim(),
                    ));
                    ref.invalidate(productsProvider(businessId));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Update Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context, WidgetRef ref, Product product, String businessId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(productRepositoryProvider).deleteProduct(product.id);
      ref.invalidate(productsProvider(businessId));
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
