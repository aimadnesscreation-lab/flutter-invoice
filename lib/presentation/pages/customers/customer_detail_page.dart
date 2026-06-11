import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/customer.dart';
import 'package:invoice_pro/domain/entities/invoice.dart';

class CustomerDetailPage extends ConsumerWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final colorScheme = Theme.of(context).colorScheme;
    final customersAsync = ref.watch(customersProvider(businessId));
    final invoicesAsync = ref.watch(invoicesProvider(businessId));

    return customersAsync.when(
      data: (customers) {
        final customer = customers.where((c) => c.id == customerId).firstOrNull;
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editCustomer(context, ref, customer),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCustomer(context, ref, customer, businessId),
              ),
            ],
          ),
          body: invoicesAsync.when(
            data: (invoices) {
              final customerInvoices = invoices.where((inv) => inv.customerId == customerId).toList();
              return _buildBody(context, customer, customerInvoices, colorScheme);
            },
            loading: () => _buildBody(context, customer, [], colorScheme),
            error: (e, _) => _buildBody(context, customer, [], colorScheme),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildBody(BuildContext context, Customer customer, List<Invoice> invoices, ColorScheme colorScheme) {
    final totalPurchases = invoices.fold<double>(0.0, (sum, inv) => sum + inv.grandTotal);
    final outstanding = invoices
      .where((inv) => inv.status != 'paid' && inv.status != 'cancelled')
      .fold<double>(0.0, (sum, inv) => sum + inv.balanceDue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 24, color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
                            if (customer.email != null) Text(customer.email!, style: Theme.of(context).textTheme.bodyMedium),
                            if (customer.phone != null) Text(customer.phone!, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (customer.address != null) _buildInfoRow('Address', customer.address!),
                  if (customer.taxNumber != null) _buildInfoRow('Tax Number', customer.taxNumber!),
                  if (customer.notes != null) _buildInfoRow('Notes', customer.notes!),
                  _buildInfoRow('Customer Since', Helpers.formatDate(customer.createdAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats from actual invoices
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer History', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('Total Invoices', '${invoices.length}')),
                      Expanded(child: _buildStatItem('Total Purchases', Helpers.formatCurrency(totalPurchases))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('Outstanding', Helpers.formatCurrency(outstanding))),
                      Expanded(child: _buildStatItem('Last Invoice', invoices.isNotEmpty ? Helpers.formatDate(invoices.first.invoiceDate) : 'N/A')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer Invoices
          Text('Invoices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (invoices.isEmpty)
            Card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('No invoices yet', style: Theme.of(context).textTheme.bodyMedium)),
            ))
          else
            ...invoices.take(5).map((inv) => Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                title: Text(inv.invoiceNumber),
                subtitle: Text(Helpers.formatDate(inv.invoiceDate)),
                trailing: Text(Helpers.formatCurrency(inv.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => context.go('/invoices/${inv.id}'),
              ),
            )),
        ],
      ),
    );
  }

  void _editCustomer(BuildContext context, WidgetRef ref, Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final emailController = TextEditingController(text: customer.email ?? '');
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final addressController = TextEditingController(text: customer.address ?? '');
    final taxNumberController = TextEditingController(text: customer.taxNumber ?? '');
    final notesController = TextEditingController(text: customer.notes ?? '');

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
              Text('Edit Customer', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person)), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
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
                    final businessId = ref.read(activeBusinessProvider)?.id ?? 'default';
                    final repo = ref.read(customerRepositoryProvider);
                    await repo.updateCustomer(customer.copyWith(
                      name: nameController.text.trim(),
                      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                      taxNumber: taxNumberController.text.trim().isEmpty ? null : taxNumberController.text.trim(),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    ));
                    ref.invalidate(customersProvider(businessId));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Update Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteCustomer(BuildContext context, WidgetRef ref, Customer customer, String businessId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "${customer.name}"? This will soft-delete the customer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(customerRepositoryProvider).deleteCustomer(customer.id);
      ref.invalidate(customersProvider(businessId));
      if (context.mounted) context.pop();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
