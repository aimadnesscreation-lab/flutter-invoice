import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/domain/entities/supplier.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
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
    final businessId = business?.id ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: businessId.isEmpty
          ? const Center(child: Text('Please set up a business first'))
          : _buildBody(businessId, colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierForm(context, businessId),
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }

  Widget _buildBody(String businessId, ColorScheme colorScheme) {
    return FutureBuilder<List<Supplier>>(
      future: ref.read(supplierRepositoryProvider).getAllSuppliers(businessId, searchQuery: _searchQuery.isEmpty ? null : _searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final suppliers = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search suppliers...',
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
              child: suppliers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_outlined, size: 64, color: colorScheme.onSurfaceVariant.withAlpha(100)),
                          const SizedBox(height: 16),
                          const Text('No suppliers found'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: suppliers.length,
                      itemBuilder: (context, index) => _buildSupplierCard(context, suppliers[index], businessId),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierCard(BuildContext context, Supplier supplier, String businessId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(supplier.name),
        subtitle: Text(supplier.contactPerson ?? supplier.email ?? supplier.phone ?? 'No contact info'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showSupplierForm(context, businessId, supplier: supplier);
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete Supplier'),
                  content: Text('Delete "${supplier.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(supplierRepositoryProvider).deleteSupplier(supplier.id);
                setState(() {});
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
          ],
        ),
      ),
    );
  }

  void _showSupplierForm(BuildContext context, String businessId, {Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');
    final taxNumberController = TextEditingController(text: supplier?.taxNumber ?? '');
    final contactPersonController = TextEditingController(text: supplier?.contactPerson ?? '');
    final notesController = TextEditingController(text: supplier?.notes ?? '');

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
              Text(supplier == null ? 'Add Supplier' : 'Edit Supplier', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.store)), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: contactPersonController, decoration: const InputDecoration(labelText: 'Contact Person', prefixIcon: Icon(Icons.person)), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: taxNumberController, decoration: const InputDecoration(labelText: 'Tax Number', prefixIcon: Icon(Icons.numbers))),
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)), maxLines: 3),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final repo = ref.read(supplierRepositoryProvider);
                    if (supplier == null) {
                      await repo.createSupplier(Supplier(
                        id: const Uuid().v4(),
                        businessId: businessId,
                        name: nameController.text.trim(),
                        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                        taxNumber: taxNumberController.text.trim().isEmpty ? null : taxNumberController.text.trim(),
                        contactPerson: contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ));
                    } else {
                      await repo.updateSupplier(supplier.copyWith(
                        name: nameController.text.trim(),
                        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                        taxNumber: taxNumberController.text.trim().isEmpty ? null : taxNumberController.text.trim(),
                        contactPerson: contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      ));
                    }
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(supplier == null ? 'Create Supplier' : 'Update Supplier'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
