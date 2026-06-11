import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/payment.dart';

class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsProvider('default'));

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('No payments recorded'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) => _buildPaymentCard(context, payments[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: payment.isRefund ? Colors.red.withAlpha(30) : Colors.green.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            payment.isRefund ? Icons.money_off : Icons.payment,
            color: payment.isRefund ? Colors.red : Colors.green,
          ),
        ),
        title: Text('${payment.paymentNumber} · ${payment.method.replaceAll('_', ' ').toUpperCase()}'),
        subtitle: Text(
          '${payment.customerName ?? "N/A"} · ${Helpers.formatDate(payment.paymentDate)}${payment.isRefund ? " · REFUND" : ""}',
        ),
        trailing: Text(
          Helpers.formatCurrency(payment.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: payment.isRefund ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    final methodController = TextEditingController();
    final refController = TextEditingController();

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
            Text('Record Payment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.money)), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Method', prefixIcon: Icon(Icons.payment)),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                DropdownMenuItem(value: 'debit_card', child: Text('Debit Card')),
                DropdownMenuItem(value: 'mobile_wallet', child: Text('Mobile Wallet')),
              ],
              onChanged: (v) => methodController.text = v ?? 'cash',
            ),
            const SizedBox(height: 12),
            TextField(controller: refController, decoration: const InputDecoration(labelText: 'Reference', prefixIcon: Icon(Icons.bookmark))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
