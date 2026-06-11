import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final invoicesAsync = ref.watch(invoicesProvider(businessId));
    final customersAsync = ref.watch(customersProvider(businessId));
    final productsAsync = ref.watch(productsProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search invoices, customers, products...',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _buildBody(invoicesAsync, customersAsync, productsAsync),
    );
  }

  Widget _buildBody(
    AsyncValue<List<dynamic>> invoicesAsync,
    AsyncValue<List<dynamic>> customersAsync,
    AsyncValue<List<dynamic>> productsAsync,
  ) {
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 16),
            const Text('Start typing to search'),
          ],
        ),
      );
    }

    if (invoicesAsync.isLoading || customersAsync.isLoading || productsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final invoices = invoicesAsync.valueOrNull ?? [];
    final customers = customersAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];

    final invoiceResults = invoices.where((inv) =>
      (inv.invoiceNumber as String).toLowerCase().contains(_query) ||
      (inv.customerName?.toString().toLowerCase().contains(_query) ?? false)
    ).toList();

    final customerResults = customers.where((c) =>
      (c.name as String).toLowerCase().contains(_query) ||
      (c.email?.toString().toLowerCase().contains(_query) ?? false) ||
      (c.phone?.toString().contains(_query) ?? false)
    ).toList();

    final productResults = products.where((p) =>
      (p.name as String).toLowerCase().contains(_query) ||
      (p.sku?.toString().toLowerCase().contains(_query) ?? false)
    ).toList();

    final totalResults = invoiceResults.length + customerResults.length + productResults.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 16),
            Text('No results for "$_query"'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (invoiceResults.isNotEmpty) ...[
          _buildSectionHeader('Invoices (${invoiceResults.length})'),
          ...invoiceResults.take(5).map((inv) => Card(
            child: ListTile(
              leading: const Icon(Icons.receipt),
              title: Text(inv.invoiceNumber),
              subtitle: Text('${inv.customerName ?? "N/A"} · ${Helpers.formatCurrency(inv.grandTotal)}'),
              onTap: () => context.go('/invoices/${inv.id}'),
            ),
          )),
        ],
        if (customerResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSectionHeader('Customers (${customerResults.length})'),
          ...customerResults.take(5).map((c) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(c.name[0].toUpperCase())),
              title: Text(c.name),
              subtitle: Text(c.email ?? c.phone ?? ''),
              onTap: () => context.go('/customers/${c.id}'),
            ),
          )),
        ],
        if (productResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSectionHeader('Products (${productResults.length})'),
          ...productResults.take(5).map((p) => Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text(p.name),
              subtitle: Text('${p.sku ?? "No SKU"} · ${Helpers.formatCurrency(p.sellingPrice)}'),
              onTap: () {},
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
