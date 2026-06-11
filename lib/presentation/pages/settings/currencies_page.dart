import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/domain/entities/currency_entity.dart';

class CurrenciesPage extends ConsumerStatefulWidget {
  const CurrenciesPage({super.key});

  @override
  ConsumerState<CurrenciesPage> createState() => _CurrenciesPageState();
}

class _CurrenciesPageState extends ConsumerState<CurrenciesPage> {
  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Currencies')),
      body: businessId.isEmpty
          ? const Center(child: Text('Please set up a business first'))
          : _buildBody(businessId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCurrencyForm(context, businessId),
        icon: const Icon(Icons.add),
        label: const Text('Add Currency'),
      ),
    );
  }

  Widget _buildBody(String businessId) {
    return FutureBuilder<List<CurrencyEntity>>(
      future: ref.read(currencyRepositoryProvider).getAllCurrencies(businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final currencies = snapshot.data ?? [];
        if (currencies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.currency_exchange, size: 64, color: Colors.grey.withAlpha(100)),
                const SizedBox(height: 16),
                const Text('No currencies configured'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: currencies.length,
          itemBuilder: (context, index) => _buildCurrencyCard(context, currencies[index], businessId),
        );
      },
    );
  }

  Widget _buildCurrencyCard(BuildContext context, CurrencyEntity currency, String businessId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            currency.symbol,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text('${currency.code} - ${currency.name}'),
        subtitle: Text('Rate: ${currency.exchangeRate.toStringAsFixed(4)}${currency.isDefault ? " · Default" : ""}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showCurrencyForm(context, businessId, currency: currency);
            } else if (value == 'delete') {
              await ref.read(currencyRepositoryProvider).deleteCurrency(currency.id);
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

  void _showCurrencyForm(BuildContext context, String businessId, {CurrencyEntity? currency}) {
    final codeController = TextEditingController(text: currency?.code ?? '');
    final nameController = TextEditingController(text: currency?.name ?? '');
    final symbolController = TextEditingController(text: currency?.symbol ?? '');
    final rateController = TextEditingController(text: currency?.exchangeRate.toString() ?? '1.0');
    bool isDefault = currency?.isDefault ?? false;

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
              Text(currency == null ? 'Add Currency' : 'Edit Currency', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code *', prefixIcon: Icon(Icons.tag), hintText: 'USD')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(controller: symbolController, decoration: const InputDecoration(labelText: 'Symbol *', prefixIcon: Icon(Icons.money), hintText: '\$')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.label), hintText: 'US Dollar')),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                decoration: const InputDecoration(labelText: 'Exchange Rate', prefixIcon: Icon(Icons.trending_up), hintText: '1.0'),
                keyboardType: TextInputType.number,
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
                    if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
                    final rate = double.tryParse(rateController.text) ?? 1.0;

                    final repo = ref.read(currencyRepositoryProvider);
                    if (currency == null) {
                      await repo.createCurrency(CurrencyEntity(
                        id: const Uuid().v4(),
                        businessId: businessId,
                        code: codeController.text.trim().toUpperCase(),
                        name: nameController.text.trim(),
                        symbol: symbolController.text.trim().isEmpty ? '\$' : symbolController.text.trim(),
                        exchangeRate: rate,
                        isDefault: isDefault,
                        createdAt: DateTime.now(),
                      ));
                    } else {
                      await repo.updateCurrency(currency.copyWith(
                        code: codeController.text.trim().toUpperCase(),
                        name: nameController.text.trim(),
                        symbol: symbolController.text.trim().isEmpty ? '\$' : symbolController.text.trim(),
                        exchangeRate: rate,
                        isDefault: isDefault,
                      ));
                    }
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(currency == null ? 'Add Currency' : 'Update Currency'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
