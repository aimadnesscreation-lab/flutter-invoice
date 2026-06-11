import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/domain/entities/customer.dart';
import 'package:invoice_pro/presentation/widgets/shimmer_loading.dart';
import 'package:uuid/uuid.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
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
    final customersAsync = ref.watch(
      _searchQuery.isEmpty
          ? customersProvider(businessId)
          : customerSearchProvider({'businessId': businessId, 'query': _searchQuery}),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() => _searchQuery = '');
                _searchController.clear();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
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

          // List
          Expanded(
            child: customersAsync.when(
              data: (customers) => customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: colorScheme.onSurfaceVariant.withAlpha(100)),
                          const SizedBox(height: 16),
                          Text('No customers found', style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) => _buildCustomerCard(context, customers[index]),
                    ),
              loading: () => const ShimmerLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(customer.name),
        subtitle: Text(customer.email ?? customer.phone ?? 'No contact info'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showCustomerForm(context, customer: customer),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteCustomer(context, customer),
            ),
          ],
        ),
        onTap: () => context.go('/customers/${customer.id}'),
      ),
    );
  }

  void _showCustomerForm(BuildContext context, {Customer? customer}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer?.name ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    final taxNumberController = TextEditingController(text: customer?.taxNumber ?? '');
    final notesController = TextEditingController(text: customer?.notes ?? '');

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
                Text(customer == null ? 'Add Customer' : 'Edit Customer', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person)),
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required('Name', v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.email(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) => Validators.phone(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: taxNumberController, decoration: const InputDecoration(labelText: 'Tax Number', prefixIcon: Icon(Icons.numbers))),
              const SizedBox(height: 12),
              TextFormField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)), maxLines: 3),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final business = ref.read(activeBusinessProvider);
                    final businessId = business?.id ?? 'default';
                    final repo = ref.read(customerRepositoryProvider);
                    if (customer == null) {
                      await repo.createCustomer(Customer(
                        id: const Uuid().v4(),
                        businessId: businessId,
                        name: nameController.text.trim(),
                        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                        taxNumber: taxNumberController.text.trim().isEmpty ? null : taxNumberController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ));
                    } else {
                      await repo.updateCustomer(customer.copyWith(
                        name: nameController.text.trim(),
                        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                        taxNumber: taxNumberController.text.trim().isEmpty ? null : taxNumberController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      ));
                    }
                    ref.invalidate(customersProvider(businessId));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(customer == null ? 'Create Customer' : 'Update Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _deleteCustomer(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete "${customer.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final businessId = ref.read(activeBusinessProvider)?.id ?? 'default';
              await ref.read(customerRepositoryProvider).deleteCustomer(customer.id);
              ref.invalidate(customersProvider(businessId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
