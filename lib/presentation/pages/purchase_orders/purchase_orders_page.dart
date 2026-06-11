import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/core/utils/validators.dart';
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
        onPressed: () => _showCreateForm(context),
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
        onTap: () => context.go('/invoices/${po.id}'),
      ),
    );
  }

  void _showCreateForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final business = ref.read(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final itemDescController = TextEditingController(text: 'Item 1');
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedSupplierId;
    String? selectedSupplierName;
    bool supplierSelected = false;

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
                Text('New Purchase Order', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _supplierDropdown(context, (id, name) {
                  selectedSupplierId = id;
                  selectedSupplierName = name;
                  supplierSelected = true;
                }, formKey: formKey),
                const SizedBox(height: 12),
                TextFormField(
                  controller: itemDescController,
                  decoration: const InputDecoration(labelText: 'Item Description *', prefixIcon: Icon(Icons.description)),
                  validator: (v) => Validators.required('Item Description', v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: qtyController,
                        decoration: const InputDecoration(labelText: 'Quantity *', prefixIcon: Icon(Icons.numbers)),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveNumber(v, fieldName: 'Quantity'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Unit Price *', prefixIcon: Icon(Icons.money)),
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveNumber(v, fieldName: 'Unit Price'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (!supplierSelected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a supplier')),
                        );
                        return;
                      }
                    final prefix = business?.purchaseOrderPrefix ?? 'PO-';
                    final num = await ref.read(invoiceRepositoryProvider).generateInvoiceNumber(businessId, prefix);
                    final qty = double.tryParse(qtyController.text) ?? 1;
                    final price = double.tryParse(priceController.text) ?? 0;

                    await ref.read(invoiceRepositoryProvider).createInvoice(Invoice(
                      id: const Uuid().v4(),
                      businessId: businessId,
                      supplierId: selectedSupplierId,
                      supplierName: selectedSupplierName,
                      invoiceNumber: num,
                      status: 'draft',
                      invoiceDate: DateTime.now(),
                      dueDate: DateTime.now().add(const Duration(days: 30)),
                      subtotal: qty * price,
                      grandTotal: qty * price,
                      balanceDue: qty * price,
                      isPurchaseOrder: true,
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ), [
                      InvoiceItem(
                        id: const Uuid().v4(),
                        invoiceId: '',
                        description: itemDescController.text,
                        quantity: qty,
                        unitPrice: price,
                        subtotal: qty * price,
                      ),
                    ]);

                    ref.invalidate(invoicesProvider(businessId));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Create Purchase Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _supplierDropdown(BuildContext context, Function(String, String?) onSelected, {GlobalKey<FormState>? formKey}) {
    final businessId = ref.read(activeBusinessProvider)?.id ?? 'default';
    final suppliersAsync = ref.watch(suppliersProvider(businessId));

    return suppliersAsync.when(
      data: (suppliers) => DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Supplier *', prefixIcon: Icon(Icons.store)),
        items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
        onChanged: (id) {
          final supplier = suppliers.where((s) => s.id == id).firstOrNull;
          onSelected(id ?? '', supplier?.name);
          formKey?.currentState?.validate();
        },
        validator: (v) => Validators.required('Supplier', v),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
