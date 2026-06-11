import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/domain/entities/tax_rate.dart';

class TaxRatesPage extends ConsumerStatefulWidget {
  const TaxRatesPage({super.key});

  @override
  ConsumerState<TaxRatesPage> createState() => _TaxRatesPageState();
}

class _TaxRatesPageState extends ConsumerState<TaxRatesPage> {
  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Rates'),
      ),
      body: businessId.isEmpty
          ? const Center(child: Text('Please set up a business first'))
          : _buildBody(businessId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaxRateForm(context, businessId),
        icon: const Icon(Icons.add),
        label: const Text('Add Tax Rate'),
      ),
    );
  }

  Widget _buildBody(String businessId) {
    return FutureBuilder<List<TaxRate>>(
      future: ref.read(taxRateRepositoryProvider).getAllTaxRates(businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final rates = snapshot.data ?? [];
        if (rates.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt, size: 64, color: Colors.grey.withAlpha(100)),
                const SizedBox(height: 16),
                const Text('No tax rates configured'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rates.length,
          itemBuilder: (context, index) => _buildTaxRateCard(context, rates[index], businessId),
        );
      },
    );
  }

  Widget _buildTaxRateCard(BuildContext context, TaxRate rate, String businessId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${rate.rate.toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
        ),
        title: Text(rate.name),
        subtitle: Text('${rate.type.replaceAll('_', ' ').toUpperCase()}${rate.isDefault ? " · Default" : ""}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showTaxRateForm(context, businessId, rate: rate);
            } else if (value == 'delete') {
              await ref.read(taxRateRepositoryProvider).deleteTaxRate(rate.id);
              setState(() {});
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _showTaxRateForm(BuildContext context, String businessId, {TaxRate? rate}) {
    final nameController = TextEditingController(text: rate?.name ?? '');
    final rateController = TextEditingController(text: rate?.rate.toString() ?? '');
    String selectedType = rate?.type ?? 'vat';
    bool isDefault = rate?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rate == null ? 'Add Tax Rate' : 'Edit Tax Rate', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.label)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                decoration: const InputDecoration(labelText: 'Rate %', prefixIcon: Icon(Icons.percent), suffixText: '%'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                items: const [
                  DropdownMenuItem(value: 'gst', child: Text('GST')),
                  DropdownMenuItem(value: 'vat', child: Text('VAT')),
                  DropdownMenuItem(value: 'sales_tax', child: Text('Sales Tax')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v ?? 'vat'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Set as default'),
                value: isDefault,
                onChanged: (v) => setDialogState(() => isDefault = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final rateValue = double.tryParse(rateController.text);
                    if (rateValue == null || rateValue < 0) return;

                    final repo = ref.read(taxRateRepositoryProvider);
                    if (rate == null) {
                      await repo.createTaxRate(TaxRate(
                        id: const Uuid().v4(),
                        businessId: businessId,
                        name: nameController.text.trim(),
                        type: selectedType,
                        rate: rateValue,
                        isDefault: isDefault,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ));
                    } else {
                      await repo.updateTaxRate(rate.copyWith(
                        name: nameController.text.trim(),
                        type: selectedType,
                        rate: rateValue,
                        isDefault: isDefault,
                      ));
                    }
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(rate == null ? 'Add Tax Rate' : 'Update Tax Rate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
