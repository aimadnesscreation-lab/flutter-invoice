import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/domain/entities/business.dart';

class BusinessSettingsPage extends ConsumerStatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  ConsumerState<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends ConsumerState<BusinessSettingsPage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _invoicePrefixController = TextEditingController();
  final _estimatePrefixController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCurrency = 'USD';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentBusinessId;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    final business = ref.read(activeBusinessProvider);
    if (business != null) {
      _nameController.text = business.name;
      _addressController.text = business.address ?? '';
      _phoneController.text = business.phone ?? '';
      _emailController.text = business.email ?? '';
      _taxNumberController.text = business.taxNumber ?? '';
      _invoicePrefixController.text = business.invoicePrefix;
      _estimatePrefixController.text = business.estimatePrefix;
      _notesController.text = business.notes ?? '';
      _selectedCurrency = business.currency;
      _currentBusinessId = business.id;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxNumberController.dispose();
    _invoicePrefixController.dispose();
    _estimatePrefixController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveBusiness,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Information', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Business Name *', prefixIcon: Icon(Icons.business)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _taxNumberController,
              decoration: const InputDecoration(labelText: 'Tax Number', prefixIcon: Icon(Icons.numbers)),
            ),
            const SizedBox(height: 24),
            Text('Document Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _invoicePrefixController,
                    decoration: const InputDecoration(labelText: 'Invoice Prefix', prefixIcon: Icon(Icons.receipt)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _estimatePrefixController,
                    decoration: const InputDecoration(labelText: 'Estimate Prefix', prefixIcon: Icon(Icons.request_quote)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              decoration: const InputDecoration(labelText: 'Currency', prefixIcon: Icon(Icons.currency_exchange)),
              items: const [
                DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar (\$)')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro (€)')),
                DropdownMenuItem(value: 'GBP', child: Text('GBP - British Pound (£)')),
                DropdownMenuItem(value: 'JPY', child: Text('JPY - Japanese Yen (¥)')),
                DropdownMenuItem(value: 'CAD', child: Text('CAD - Canadian Dollar (\$)')),
                DropdownMenuItem(value: 'AUD', child: Text('AUD - Australian Dollar (\$)')),
                DropdownMenuItem(value: 'INR', child: Text('INR - Indian Rupee (₹)')),
              ],
              onChanged: (v) => setState(() => _selectedCurrency = v ?? 'USD'),
            ),
            const SizedBox(height: 24),
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Business Notes', prefixIcon: Icon(Icons.notes)),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBusiness() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(businessRepositoryProvider);
      final now = DateTime.now();

      if (_currentBusinessId == null) {
        final business = Business(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          taxNumber: _taxNumberController.text.trim().isEmpty ? null : _taxNumberController.text.trim(),
          currency: _selectedCurrency,
          currencySymbol: _getCurrencySymbol(_selectedCurrency),
          invoicePrefix: _invoicePrefixController.text.trim().isEmpty ? 'INV-' : _invoicePrefixController.text.trim(),
          estimatePrefix: _estimatePrefixController.text.trim().isEmpty ? 'EST-' : _estimatePrefixController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await repo.createBusiness(business);
        await ref.read(activeBusinessProvider.notifier).setActiveBusiness(business.id);
      } else {
        await repo.updateBusiness(Business(
          id: _currentBusinessId!,
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          taxNumber: _taxNumberController.text.trim().isEmpty ? null : _taxNumberController.text.trim(),
          currency: _selectedCurrency,
          currencySymbol: _getCurrencySymbol(_selectedCurrency),
          invoicePrefix: _invoicePrefixController.text.trim().isEmpty ? 'INV-' : _invoicePrefixController.text.trim(),
          estimatePrefix: _estimatePrefixController.text.trim().isEmpty ? 'EST-' : _estimatePrefixController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      ref.invalidate(activeBusinessProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'CAD': return '\$';
      case 'AUD': return '\$';
      case 'INR': return '₹';
      default: return '\$';
    }
  }
}
