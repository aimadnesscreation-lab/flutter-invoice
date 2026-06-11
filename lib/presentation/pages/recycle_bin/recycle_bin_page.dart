import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/utils/helpers.dart';

class RecycleBinPage extends ConsumerStatefulWidget {
  const RecycleBinPage({super.key});

  @override
  ConsumerState<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends ConsumerState<RecycleBinPage> {
  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(activeBusinessProvider)?.id ?? '';
    final trashAsync = ref.watch(trashProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          trashAsync.when(
            data: (items) => items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () => _emptyTrash(businessId),
                    tooltip: 'Empty Trash',
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (err, stack) => const SizedBox(),
          ),
        ],
      ),
      body: trashAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('Recycle bin is empty'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(trashProvider(businessId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildDeletedItemCard(items[index], businessId),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDeletedItemCard(Map<String, dynamic> item, String businessId) {
    final entityType = item['entity_type'] as String;
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(item['deleted_at'] as int);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(item['expires_at'] as int);
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
          onPressed: () => _restoreItem(item, businessId),
        ),
      ),
    );
  }

  Future<void> _restoreItem(Map<String, dynamic> item, String businessId) async {
    try {
      final entityType = item['entity_type'] as String;
      final entityId = item['entity_id'] as String;
      final trashRepo = ref.read(trashRepositoryProvider);
      
      // Perform restoration logic based on entity type
      // Since repositories already have restore methods, we should use them
      switch (entityType) {
        case 'customer':
          await ref.read(customerRepositoryProvider).restoreCustomer(entityId);
          break;
        case 'product':
          await ref.read(productRepositoryProvider).restoreProduct(entityId);
          break;
        case 'invoice':
          await ref.read(invoiceRepositoryProvider).restoreInvoice(entityId);
          break;
        // Add other cases as needed
      }

      await trashRepo.restoreFromTrash(item['id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entityType[0].toUpperCase()}${entityType.substring(1)} restored')),
        );
      }
      ref.invalidate(trashProvider(businessId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _emptyTrash(String businessId) async {
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
        await ref.read(trashRepositoryProvider).emptyTrash(businessId);
        ref.invalidate(trashProvider(businessId));
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
