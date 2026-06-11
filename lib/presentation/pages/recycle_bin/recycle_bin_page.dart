import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:invoice_pro/core/di/injection_container.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/core/utils/helpers.dart';

class RecycleBinPage extends ConsumerStatefulWidget {
  const RecycleBinPage({super.key});

  @override
  ConsumerState<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends ConsumerState<RecycleBinPage> {
  List<Map<String, dynamic>> _deletedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    setState(() => _isLoading = true);
    try {
      final db = sl<AppDatabase>();
      final rows = await (db.select(db.deletedItems)
        ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)])
        ..limit(50)).get();

      _deletedItems = rows.map((r) => {
        'id': r.id,
        'entityType': r.entityType,
        'entityId': r.entityId,
        'entityData': r.entityData,
        'deletedAt': DateTime.fromMillisecondsSinceEpoch(r.deletedAt),
        'expiresAt': DateTime.fromMillisecondsSinceEpoch(r.expiresAt),
      }).toList();
    } catch (e) {
      _deletedItems = [];
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (!_isLoading && _deletedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _emptyTrash,
              tooltip: 'Empty Trash',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                      const SizedBox(height: 16),
                      const Text('Recycle bin is empty'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDeletedItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deletedItems.length,
                    itemBuilder: (context, index) => _buildDeletedItemCard(_deletedItems[index]),
                  ),
                ),
    );
  }

  Widget _buildDeletedItemCard(Map<String, dynamic> item) {
    final entityType = item['entityType'] as String;
    final deletedAt = item['deletedAt'] as DateTime;
    final expiresAt = item['expiresAt'] as DateTime;
    final daysLeft = expiresAt.difference(DateTime.now()).inDays;

    IconData icon;
    switch (entityType) {
      case 'customer': icon = Icons.person; break;
      case 'product': icon = Icons.inventory_2; break;
      case 'invoice': icon = Icons.receipt; break;
      case 'expense': icon = Icons.money_off; break;
      default: icon = Icons.delete;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red, size: 20),
        ),
        title: Text('${entityType[0].toUpperCase()}${entityType.substring(1)}'),
        subtitle: Text('Deleted: ${Helpers.formatDateTime(deletedAt)} · Expires in $daysLeft days'),
        trailing: IconButton(
          icon: const Icon(Icons.restore, color: Colors.green),
          tooltip: 'Restore',
          onPressed: () => _restoreItem(item),
        ),
      ),
    );
  }

  Future<void> _restoreItem(Map<String, dynamic> item) async {
    try {
      final db = sl<AppDatabase>();
      final entityType = item['entityType'] as String;
      final entityId = item['entityId'] as String;
      await db.transaction(() async {
        // Restore by setting deletedAt to null
        switch (entityType) {
          case 'customer':
            await (db.update(db.customers)..where((t) => t.id.equals(entityId))).write(
              CustomersCompanion(deletedAt: Value(null)),
            );
            break;
          case 'product':
            await (db.update(db.products)..where((t) => t.id.equals(entityId))).write(
              ProductsCompanion(deletedAt: Value(null)),
            );
            break;
          case 'invoice':
            await (db.update(db.invoices)..where((t) => t.id.equals(entityId))).write(
              InvoicesCompanion(deletedAt: Value(null)),
            );
            break;
          case 'expense':
            await (db.update(db.expenses)..where((t) => t.id.equals(entityId))).write(
              ExpensesCompanion(deletedAt: Value(null)),
            );
            break;
        }

        // Remove from deleted_items
        await (db.delete(db.deletedItems)..where((t) => t.id.equals(item['id'] as String))).go();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entityType[0].toUpperCase()}${entityType.substring(1)} restored')),
        );
      }
      _loadDeletedItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Recycle Bin'),
        content: const Text('Are you sure? All deleted items will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Empty', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = sl<AppDatabase>();
        await (db.delete(db.deletedItems)).go();
        _loadDeletedItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recycle bin emptied')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
