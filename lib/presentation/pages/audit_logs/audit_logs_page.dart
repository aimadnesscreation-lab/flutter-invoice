import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';

class AuditLogsPage extends ConsumerStatefulWidget {
  const AuditLogsPage({super.key});

  @override
  ConsumerState<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends ConsumerState<AuditLogsPage> {
  String? _selectedEntityType;

  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(activeBusinessProvider)?.id ?? '';
    final logsAsync = ref.watch(auditLogsProvider({
      'businessId': businessId,
      'entityType': _selectedEntityType,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedEntityType = value == 'all' ? null : value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All', style: TextStyle(fontWeight: _selectedEntityType == null ? FontWeight.bold : FontWeight.normal))),
              PopupMenuItem(value: 'customer', child: Text('Customers', style: TextStyle(fontWeight: _selectedEntityType == 'customer' ? FontWeight.bold : FontWeight.normal))),
              PopupMenuItem(value: 'product', child: Text('Products', style: TextStyle(fontWeight: _selectedEntityType == 'product' ? FontWeight.bold : FontWeight.normal))),
              PopupMenuItem(value: 'invoice', child: Text('Invoices', style: TextStyle(fontWeight: _selectedEntityType == 'invoice' ? FontWeight.bold : FontWeight.normal))),
              PopupMenuItem(value: 'payment', child: Text('Payments', style: TextStyle(fontWeight: _selectedEntityType == 'payment' ? FontWeight.bold : FontWeight.normal))),
              PopupMenuItem(value: 'expense', child: Text('Expenses', style: TextStyle(fontWeight: _selectedEntityType == 'expense' ? FontWeight.bold : FontWeight.normal))),
            ],
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('No audit logs found'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(auditLogsProvider({
              'businessId': businessId,
              'entityType': _selectedEntityType,
            })),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) => _buildLogCard(logs[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLogCard(dynamic log) {
    final action = log.action;
    final entityType = log.entityType;

    IconData icon;
    Color color;
    switch (action) {
      case 'create':
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case 'update':
        icon = Icons.edit_outlined;
        color = Colors.blue;
        break;
      case 'delete':
        icon = Icons.delete_outline;
        color = Colors.red;
        break;
      case 'restore':
        icon = Icons.restore;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text('${action[0].toUpperCase()}${action.substring(1)} ${entityType[0].toUpperCase()}${entityType.substring(1)}'),
        subtitle: Text(
          '${log.entityId} · ${Helpers.formatDateTime(log.createdAt)}',
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => _showLogDetails(log),
      ),
    );
  }

  void _showLogDetails(dynamic log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audit Log Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildDetailRow('Action', log.action.toUpperCase()),
            _buildDetailRow('Entity Type', log.entityType.toUpperCase()),
            _buildDetailRow('Entity ID', log.entityId),
            _buildDetailRow('Date', Helpers.formatDateTime(log.createdAt)),
            const Divider(),
            Text('Changes:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  log.changes ?? 'No changes recorded',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
