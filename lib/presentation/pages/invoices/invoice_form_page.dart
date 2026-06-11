import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/domain/entities/invoice.dart';
import 'package:invoice_pro/domain/entities/product.dart';

class InvoiceFormPage extends ConsumerStatefulWidget {
  final String? invoiceId;
  final bool isPurchaseOrder;

  const InvoiceFormPage({super.key, this.invoiceId, this.isPurchaseOrder = false});

  @override
  ConsumerState<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends ConsumerState<InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _items = <InvoiceItem>[];
  final _noteController = TextEditingController();

  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _discountPercent = 0;
  double _taxPercent = 0;
  bool _isLoading = false;

  bool get isEditing => widget.invoiceId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadInvoice();
    }
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);
    try {
      final invoice = await ref.read(invoiceRepositoryProvider).getInvoiceById(widget.invoiceId!);
      if (invoice != null && mounted) {
        setState(() {
          _selectedCustomerId = invoice.customerId;
          _selectedCustomerName = invoice.customerName;
          _selectedSupplierId = invoice.supplierId;
          _selectedSupplierName = invoice.supplierName;
          _invoiceDate = invoice.invoiceDate;
          _dueDate = invoice.dueDate;
          _items.clear();
          _items.addAll(invoice.items);
          _discountPercent = invoice.discountPercent;
          _taxPercent = invoice.taxPercent;
          _noteController.text = invoice.notes ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _discountAmount => _subtotal * (_discountPercent / 100);
  double get _taxAmount => (_subtotal - _discountAmount) * (_taxPercent / 100);
  double get _grandTotal => _subtotal - _discountAmount + _taxAmount;

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final customersAsync = ref.watch(customersProvider(businessId));
    final suppliersAsync = ref.watch(suppliersProvider(businessId));
    final productsAsync = ref.watch(productsProvider(businessId));

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = widget.isPurchaseOrder 
      ? (isEditing ? 'Edit Purchase Order' : 'Create Purchase Order')
      : (isEditing ? 'Edit Invoice' : 'Create Invoice');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _isFormValid ? _saveInvoice : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer or Supplier Select
              if (widget.isPurchaseOrder)
                suppliersAsync.when(
                  data: (suppliers) => DropdownButtonFormField<String>(
                    initialValue: _selectedSupplierId,
                    decoration: const InputDecoration(labelText: 'Supplier *', prefixIcon: Icon(Icons.store)),
                    items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (id) {
                      setState(() {
                        _selectedSupplierId = id;
                        _selectedSupplierName = suppliers.where((s) => s.id == id).firstOrNull?.name;
                      });
                    },
                    validator: (v) => Validators.required('Supplier', v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                )
              else
                customersAsync.when(
                  data: (customers) => DropdownButtonFormField<String>(
                    initialValue: _selectedCustomerId,
                    decoration: const InputDecoration(labelText: 'Customer *', prefixIcon: Icon(Icons.person)),
                    items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (id) {
                      setState(() {
                        _selectedCustomerId = id;
                        _selectedCustomerName = customers.where((c) => c.id == id).firstOrNull?.name;
                      });
                    },
                    validator: (v) => Validators.required('Customer', v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),

              const SizedBox(height: 16),

              // Date Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Invoice Date', prefixIcon: Icon(Icons.calendar_today)),
                        child: Text(Helpers.formatDate(_invoiceDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Due Date', prefixIcon: Icon(Icons.event)),
                        child: Text(Helpers.formatDate(_dueDate)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Line Items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Line Items', style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: () => _addItem(context, productsAsync),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No items added yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ),
                  ),
                )
              else
                ..._items.asMap().entries.map((entry) => _buildItemCard(entry.key, entry.value)),

              const SizedBox(height: 24),

              // Discount and Tax
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Discount %', prefixIcon: Icon(Icons.discount), suffixText: '%'),
                      keyboardType: TextInputType.number,
                      initialValue: _discountPercent > 0 ? _discountPercent.toString() : '',
                      onChanged: (v) => setState(() => _discountPercent = double.tryParse(v) ?? 0),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty && double.tryParse(v.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Tax %', prefixIcon: Icon(Icons.receipt), suffixText: '%'),
                      keyboardType: TextInputType.number,
                      initialValue: _taxPercent > 0 ? _taxPercent.toString() : '',
                      onChanged: (v) => setState(() => _taxPercent = double.tryParse(v) ?? 0),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty && double.tryParse(v.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Totals
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTotalRow('Subtotal', Helpers.formatCurrency(_subtotal)),
                      if (_discountPercent > 0) _buildTotalRow('Discount ($_discountPercent%)', '-${Helpers.formatCurrency(_discountAmount)}'),
                      _buildTotalRow('Tax ($_taxPercent%)', Helpers.formatCurrency(_taxAmount)),
                      const Divider(),
                      _buildTotalRow('Total', Helpers.formatCurrency(_grandTotal), bold: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, InvoiceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500))),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _items.removeAt(index)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Qty: ${item.quantity.toInt()} × ${Helpers.formatCurrency(item.unitPrice)}'),
                ),
                Text(Helpers.formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (item.taxPercent > 0 || item.discountPercent > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${item.taxPercent > 0 ? "Tax: ${item.taxPercent}% " : ""}${item.discountPercent > 0 ? "Disc: ${item.discountPercent}%" : ""}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }

  void _addItem(BuildContext context, AsyncValue<List<Product>> productsAsync) {
    productsAsync.whenData((products) {
      final qtyController = TextEditingController(text: '1');
      final priceController = TextEditingController();
      final descController = TextEditingController();
      final taxController = TextEditingController(text: '0');
      final discController = TextEditingController(text: '0');
      String? selectedProductId;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Product', prefixIcon: Icon(Icons.shopping_bag)),
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (id) {
                    selectedProductId = id;
                    final product = products.where((p) => p.id == id).firstOrNull;
                    if (product != null) {
                      descController.text = product.name;
                      priceController.text = product.sellingPrice.toString();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: taxController, decoration: const InputDecoration(labelText: 'Tax %', suffixText: '%'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: discController, decoration: const InputDecoration(labelText: 'Disc %', suffixText: '%'), keyboardType: TextInputType.number)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? 1;
                final price = double.tryParse(priceController.text) ?? 0;
                final taxP = double.tryParse(taxController.text) ?? 0;
                final discP = double.tryParse(discController.text) ?? 0;
                final discAmt = price * qty * (discP / 100);
                final taxAmt = (price * qty - discAmt) * (taxP / 100);
                final subtotal = price * qty - discAmt + taxAmt;

                setState(() {
                  _items.add(InvoiceItem(
                    id: const Uuid().v4(),
                    invoiceId: '',
                    productId: selectedProductId,
                    description: descController.text,
                    quantity: qty,
                    unitPrice: price,
                    discountPercent: discP,
                    discountAmount: discAmt,
                    taxPercent: taxP,
                    taxAmount: taxAmt,
                    subtotal: subtotal,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    });
  }

  void _pickDate(BuildContext context, bool isInvoiceDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInvoiceDate ? _invoiceDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  bool get _isFormValid => (widget.isPurchaseOrder ? _selectedSupplierId != null : _selectedCustomerId != null) && _items.isNotEmpty;

  void _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormValid) return;

    setState(() => _isLoading = true);
    try {
      final business = ref.read(activeBusinessProvider);
      final businessId = business?.id ?? 'default';
      final repo = ref.read(invoiceRepositoryProvider);
      
      String invoiceNumber;
      DateTime createdAt = DateTime.now();
      
      final prefix = widget.isPurchaseOrder 
        ? (business?.purchaseOrderPrefix ?? 'PO-')
        : (business?.invoicePrefix ?? 'INV-');

      if (isEditing) {
        final existing = await repo.getInvoiceById(widget.invoiceId!);
        invoiceNumber = existing?.invoiceNumber ?? await repo.generateInvoiceNumber(businessId, prefix);
        createdAt = existing?.createdAt ?? DateTime.now();
      } else {
        invoiceNumber = await repo.generateInvoiceNumber(businessId, prefix);
      }

      final invoice = Invoice(
        id: isEditing ? widget.invoiceId! : const Uuid().v4(),
        businessId: businessId,
        customerId: _selectedCustomerId,
        customerName: _selectedCustomerName,
        supplierId: _selectedSupplierId,
        supplierName: _selectedSupplierName,
        invoiceNumber: invoiceNumber,
        status: 'draft',
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        subtotal: _subtotal,
        discountPercent: _discountPercent,
        discountAmount: _discountAmount,
        taxPercent: _taxPercent,
        taxAmount: _taxAmount,
        grandTotal: _grandTotal,
        balanceDue: _grandTotal,
        isPurchaseOrder: widget.isPurchaseOrder,
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

      if (isEditing) {
        await repo.updateInvoice(invoice, _items);
      } else {
        await repo.createInvoice(invoice, _items);
      }
      
      ref.invalidate(invoicesProvider(businessId));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving document: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
