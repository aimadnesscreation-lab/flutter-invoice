import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:invoice_pro/core/di/injection_container.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/database/app_database.dart';

class ProductCategoriesPage extends ConsumerStatefulWidget {
  const ProductCategoriesPage({super.key});

  @override
  ConsumerState<ProductCategoriesPage> createState() => _ProductCategoriesPageState();
}

class _ProductCategoriesPageState extends ConsumerState<ProductCategoriesPage> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final db = sl<AppDatabase>();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Categories')),
      body: FutureBuilder<List<ProductCategory>>(
        key: ValueKey(_refreshKey),
        future: () async {
          final query = db.select(db.productCategories)
            ..where((t) => t.businessId.equals(businessId));
          return await query.get();
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('No categories yet'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) => _buildCategoryCard(context, categories[index], businessId, db),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryForm(context, businessId, db),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ProductCategory category, String businessId, AppDatabase db) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(category.name),
        subtitle: category.description != null ? Text(category.description!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showCategoryForm(context, businessId, db, category: category),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteCategory(context, category, db),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryForm(BuildContext context, String businessId, AppDatabase db, {ProductCategory? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');

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
            Text(category == null ? 'Add Category' : 'Edit Category', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.category)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  final now = DateTime.now().millisecondsSinceEpoch;

                  if (category == null) {
                    await db.into(db.productCategories).insert(ProductCategoriesCompanion.insert(
                      id: Uuid().v4(),
                      businessId: businessId,
                      name: nameController.text.trim(),
                      description: Value<String?>(descController.text.trim().isEmpty ? null : descController.text.trim()),
                      createdAt: now,
                      updatedAt: now,
                    ));
                  } else {
                    final updateQuery = db.update(db.productCategories)
                      ..where((t) => t.id.equals(category.id));
                    await updateQuery.write(ProductCategoriesCompanion(
                      name: Value(nameController.text.trim()),
                      description: Value<String?>(descController.text.trim().isEmpty ? null : descController.text.trim()),
                      updatedAt: Value(now),
                    ));
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() => _refreshKey++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(category == null ? 'Category created' : 'Category updated')),
                    );
                  }
                },
                child: Text(category == null ? 'Create Category' : 'Update Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(BuildContext context, ProductCategory category, AppDatabase db) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${category.name}"? Products in this category will remain with no category assigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final deleteQuery = db.delete(db.productCategories)
        ..where((t) => t.id.equals(category.id));
      await deleteQuery.go();
      setState(() => _refreshKey++);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      }
    }
  }
}
