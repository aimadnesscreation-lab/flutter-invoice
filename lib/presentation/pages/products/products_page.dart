import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/domain/entities/product.dart';
import 'package:invoice_pro/presentation/pages/products/barcode_scan_page.dart';
import 'package:invoice_pro/presentation/widgets/shimmer_loading.dart';
import 'package:invoice_pro/presentation/pages/products/product_categories_page.dart';
import 'package:uuid/uuid.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final colorScheme = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(productsProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BarcodeScanPage()),
            ),
            tooltip: 'Scan Barcode',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductCategoriesPage()),
            ),
            tooltip: 'Categories',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                var filtered = products;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = products.where((p) =>
                    p.name.toLowerCase().contains(q) ||
                    (p.sku?.toLowerCase().contains(q) ?? false) ||
                    (p.barcode?.contains(q) ?? false)
                  ).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.onSurfaceVariant.withAlpha(100)),
                        const SizedBox(height: 16),
                        Text('No products found', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildProductCard(context, filtered[index], colorScheme),
                );
              },
              loading: () => const ShimmerLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: product.isLowStock
                ? const Icon(Icons.warning_amber, color: Colors.orange)
                : const Icon(Icons.inventory_2, color: Colors.green),
          ),
        ),
        title: Text(product.name),
        subtitle: Text('${product.sku ?? "No SKU"} · ${Helpers.formatCurrency(product.sellingPrice)} · Qty: ${product.quantity.toInt()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LOW', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showProductForm(context, product: product),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteProduct(context, product),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    final formKey = GlobalKey<FormState>();
    final business = ref.read(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final nameController = TextEditingController(text: product?.name ?? '');
    final skuController = TextEditingController(text: product?.sku ?? '');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final costPriceController = TextEditingController(text: product?.costPrice.toString() ?? '');
    final sellingPriceController = TextEditingController(text: product?.sellingPrice.toString() ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    final reorderLevelController = TextEditingController(text: product?.reorderLevel.toString() ?? '');
    final unitController = TextEditingController(text: product?.unit ?? 'pcs');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product == null ? 'Add Product' : 'Edit Product', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.shopping_bag)),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required('Name', v),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU', prefixIcon: Icon(Icons.tag))),
                const SizedBox(height: 12),
                TextFormField(controller: barcodeController, decoration: const InputDecoration(labelText: 'Barcode', prefixIcon: Icon(Icons.qr_code))),
                const SizedBox(height: 12),
                TextFormField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)), maxLines: 3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: costPriceController,
                        decoration: const InputDecoration(labelText: 'Cost Price', prefixIcon: Icon(Icons.money)),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveNumber(v, fieldName: 'Cost Price'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: sellingPriceController,
                        decoration: const InputDecoration(labelText: 'Selling Price', prefixIcon: Icon(Icons.attach_money)),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveNumber(v, fieldName: 'Selling Price'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers)),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.number(v, fieldName: 'Quantity'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: reorderLevelController,
                        decoration: const InputDecoration(labelText: 'Reorder Level', prefixIcon: Icon(Icons.low_priority)),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.number(v, fieldName: 'Reorder Level'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (pcs, kg, etc.)', prefixIcon: Icon(Icons.straighten))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                    final repo = ref.read(productRepositoryProvider);
                    if (product == null) {
                      await repo.createProduct(Product(
                        id: const Uuid().v4(),
                        businessId: businessId,
                        name: nameController.text.trim(),
                        sku: skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                        barcode: barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim(),
                        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                        costPrice: double.tryParse(costPriceController.text) ?? 0,
                        sellingPrice: double.tryParse(sellingPriceController.text) ?? 0,
                        quantity: double.tryParse(quantityController.text) ?? 0,
                        reorderLevel: double.tryParse(reorderLevelController.text) ?? 0,
                        unit: unitController.text.trim().isEmpty ? 'pcs' : unitController.text.trim(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ));
                    } else {
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
                    }
                    ref.invalidate(productsProvider(businessId));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(product == null ? 'Create Product' : 'Update Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _deleteProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final business = ref.read(activeBusinessProvider);
              final businessId = business?.id ?? 'default';
              await ref.read(productRepositoryProvider).deleteProduct(product.id);
              ref.invalidate(productsProvider(businessId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


