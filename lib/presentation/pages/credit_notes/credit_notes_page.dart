import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';
import 'package:invoice_pro/domain/entities/credit_note.dart';

class CreditNotesPage extends ConsumerStatefulWidget {
  const CreditNotesPage({super.key});

  @override
  ConsumerState<CreditNotesPage> createState() => _CreditNotesPageState();
}

class _CreditNotesPageState extends ConsumerState<CreditNotesPage> {
  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);
    final businessId = business?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Notes')),
      body: businessId.isEmpty
          ? const Center(child: Text('Please set up a business first'))
          : _buildBody(businessId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreditNoteForm(context, businessId),
        icon: const Icon(Icons.add),
        label: const Text('Create Credit Note'),
      ),
    );
  }

  Widget _buildBody(String businessId) {
    return FutureBuilder<List<CreditNote>>(
      future: ref.read(creditNoteRepositoryProvider).getAllCreditNotes(businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                const SizedBox(height: 16),
                const Text('No credit notes yet'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildCreditNoteCard(context, notes[index]),
        );
      },
    );
  }

  Widget _buildCreditNoteCard(BuildContext context, CreditNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: note.reason == 'return' ? Colors.orange.withAlpha(30) : Colors.blue.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            note.reason == 'return' ? Icons.assignment_return : Icons.adjust,
            color: note.reason == 'return' ? Colors.orange : Colors.blue,
          ),
        ),
        title: Text(note.creditNoteNumber),
        subtitle: Text(
          '${note.customerName ?? "N/A"} · ${note.reason.replaceAll('_', ' ').toUpperCase()} · ${Helpers.formatDate(note.creditNoteDate)}',
        ),
        trailing: Text(
          Helpers.formatCurrency(note.amount),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }

  void _showCreditNoteForm(BuildContext context, String businessId) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedReason = 'return';

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
              Text('Create Credit Note', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount *', prefixIcon: Icon(Icons.money)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: const InputDecoration(labelText: 'Reason', prefixIcon: Icon(Icons.receipt_long)),
                items: const [
                  DropdownMenuItem(value: 'return', child: Text('Return')),
                  DropdownMenuItem(value: 'refund', child: Text('Refund')),
                  DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                ],
                onChanged: (v) => setDialogState(() => selectedReason = v ?? 'return'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) return;

                    final repo = ref.read(creditNoteRepositoryProvider);
                    final cn = await repo.generateCreditNoteNumber(businessId, 'CN-');
                    await repo.createCreditNote(CreditNote(
                      id: const Uuid().v4(),
                      businessId: businessId,
                      creditNoteNumber: cn,
                      reason: selectedReason,
                      amount: amount,
                      creditNoteDate: DateTime.now(),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ));
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Create Credit Note'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
