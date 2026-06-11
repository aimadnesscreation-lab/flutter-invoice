import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/expense.dart';
import 'package:invoice_pro/presentation/widgets/shimmer_loading.dart';
import 'package:uuid/uuid.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? 'default';
    final expensesAsync = ref.watch(expensesProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedCategory = value == 'all' ? null : value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              ...Expense.categories.map((c) => PopupMenuItem(value: c, child: Text(c))),
            ],
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          var filtered = expenses;
          if (_selectedCategory != null) {
            filtered = expenses.where((e) => e.category == _selectedCategory).toList();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.money_off_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('No expenses recorded'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildExpenseCard(context, filtered[index]),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor(expense.category).withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.category, color: _getCategoryColor(expense.category)),
        ),
        title: Text(expense.category),
        subtitle: Text('${expense.expenseNumber} · ${Helpers.formatDate(expense.expenseDate)}'),
        trailing: Text(
          Helpers.formatCurrency(expense.amount),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        onTap: () {},
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Rent': return Colors.blue;
      case 'Utilities': return Colors.orange;
      case 'Salaries': return Colors.green;
      case 'Fuel': return Colors.yellow;
      case 'Office': return Colors.purple;
      case 'Marketing': return Colors.pink;
      default: return Colors.grey;
    }
  }

  void _showExpenseForm(BuildContext context) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = Expense.categories.first;

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
            Text('Add Expense', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
              items: Expense.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => selectedCategory = v ?? Expense.categories.first,
            ),
            const SizedBox(height: 12),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.money)), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)), maxLines: 3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final businessId = ref.read(activeBusinessProvider)?.id ?? 'default';
                  final repo = ref.read(expenseRepositoryProvider);
                  final expenseNumber = await repo.generateExpenseNumber(businessId, 'EXP-');
                  await repo.createExpense(Expense(
                    id: const Uuid().v4(),
                    businessId: businessId,
                    expenseNumber: expenseNumber,
                    category: selectedCategory,
                    amount: double.tryParse(amountController.text) ?? 0,
                    expenseDate: DateTime.now(),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                  ref.invalidate(expensesProvider(businessId));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
