import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';

class InvoiceSettingsPage extends ConsumerStatefulWidget {
  const InvoiceSettingsPage({super.key});

  @override
  ConsumerState<InvoiceSettingsPage> createState() => _InvoiceSettingsPageState();
}

class _InvoiceSettingsPageState extends ConsumerState<InvoiceSettingsPage> {
  final _termsController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _lateFeeController = TextEditingController();
  final _reminderController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  // Settings keys
  static const String _keyPaymentTerms = 'invoice_payment_terms';
  static const String _keyDueDateOffset = 'invoice_due_date_offset';
  static const String _keyDefaultNotes = 'invoice_default_notes';
  static const String _keyLateFeePercent = 'invoice_late_fee_percent';
  static const String _keyReminderDays = 'invoice_reminder_days';
  static const String _keyAutoEmail = 'invoice_auto_email';

  String _selectedPaymentTerms = 'net_30';
  int _dueDateOffset = 30;
  bool _autoEmailOnCreate = false;
  bool _enableLateFees = false;
  final List<Map<String, String>> _paymentTermsOptions = [
    {'value': 'due_on_receipt', 'label': 'Due on Receipt'},
    {'value': 'net_15', 'label': 'Net 15'},
    {'value': 'net_30', 'label': 'Net 30'},
    {'value': 'net_45', 'label': 'Net 45'},
    {'value': 'net_60', 'label': 'Net 60'},
    {'value': 'net_90', 'label': 'Net 90'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    try {
      final paymentTerms = await repo.getSetting(_keyPaymentTerms) ?? 'net_30';
      final dueDateOffset = await repo.getSetting(_keyDueDateOffset) ?? '30';
      final defaultNotes = await repo.getSetting(_keyDefaultNotes) ?? '';
      final lateFeePercent = await repo.getSetting(_keyLateFeePercent) ?? '0';
      final reminderDays = await repo.getSetting(_keyReminderDays) ?? '3';
      final autoEmail = await repo.getSetting(_keyAutoEmail) ?? 'false';

      setState(() {
        _selectedPaymentTerms = paymentTerms;
        _dueDateOffset = int.tryParse(dueDateOffset) ?? 30;
        _dueDateController.text = _dueDateOffset.toString();
        _termsController.text = defaultNotes;
        _lateFeeController.text = lateFeePercent;
        _reminderController.text = reminderDays;
        _autoEmailOnCreate = autoEmail == 'true';
        _enableLateFees = lateFeePercent != '0' && lateFeePercent.isNotEmpty;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _termsController.dispose();
    _dueDateController.dispose();
    _lateFeeController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Terms', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use - value: needed for dynamic updates after load
              value: _selectedPaymentTerms,
              decoration: const InputDecoration(
                labelText: 'Default Payment Terms',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: _paymentTermsOptions
                  .map((opt) => DropdownMenuItem(
                        value: opt['value'],
                        child: Text(opt['label']!),
                      ))
                  .toList(          ),
              onChanged: (v) {
                if (v != null) {
                  int newOffset;
                  if (v == 'due_on_receipt') {
                    newOffset = 0;
                  } else if (v == 'net_15') {
                    newOffset = 15;
                  } else if (v == 'net_45') {
                    newOffset = 45;
                  } else if (v == 'net_60') {
                    newOffset = 60;
                  } else if (v == 'net_90') {
                    newOffset = 90;
                  } else {
                    newOffset = 30;
                  }
                  setState(() {
                    _selectedPaymentTerms = v;
                    _dueDateOffset = newOffset;
                    _dueDateController.text = newOffset.toString();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dueDateController,
              decoration: const InputDecoration(
                labelText: 'Due Date Offset (days)',
                prefixIcon: Icon(Icons.calendar_today),
                helperText: 'Days from invoice date to due date',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _dueDateOffset = int.tryParse(v) ?? 30,
            ),
            const SizedBox(height: 24),

            Text('Default Notes & Terms', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(
                labelText: 'Default Invoice Notes',
                prefixIcon: Icon(Icons.notes),
                helperText: 'These notes will appear on every new invoice',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            Text('Late Payments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Late Fees'),
              subtitle: const Text('Automatically apply late fees on overdue invoices'),
              value: _enableLateFees,
              onChanged: (v) => setState(() => _enableLateFees = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_enableLateFees) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _lateFeeController,
                decoration: const InputDecoration(
                  labelText: 'Late Fee (%)',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reminderController,
                decoration: const InputDecoration(
                  labelText: 'Reminder (days after due date)',
                  prefixIcon: Icon(Icons.notifications),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 24),

            Text('Emails', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-email invoice on create'),
              subtitle: const Text('Automatically mark invoices as sent when created'),
              value: _autoEmailOnCreate,
              onChanged: (v) => setState(() => _autoEmailOnCreate = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setSetting(_keyPaymentTerms, _selectedPaymentTerms);
      await repo.setSetting(_keyDueDateOffset, _dueDateOffset.toString());
      await repo.setSetting(_keyDefaultNotes, _termsController.text.trim());
      await repo.setSetting(
        _keyLateFeePercent,
        _enableLateFees ? (_lateFeeController.text.trim().isEmpty ? '0' : _lateFeeController.text.trim()) : '0',
      );
      await repo.setSetting(
        _keyReminderDays,
        _enableLateFees ? (_reminderController.text.trim().isEmpty ? '3' : _reminderController.text.trim()) : '3',
      );
      await repo.setSetting(_keyAutoEmail, _autoEmailOnCreate.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice settings saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
