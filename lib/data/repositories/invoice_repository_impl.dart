import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/invoice_model.dart';
import 'package:invoice_pro/domain/entities/invoice.dart' as domain;
import 'package:invoice_pro/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final AppDatabase _db;

  InvoiceRepositoryImpl(this._db);

  @override
  Future<List<domain.Invoice>> getAllInvoices(String businessId, {String? status, String? searchQuery, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    
    final query = _db.select(_db.invoices).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.invoices.supplierId)),
    ])
      ..where(_db.invoices.businessId.equals(businessId))
      ..where(_db.invoices.deletedAt.isNull());

    if (status != null) {
      query.where(_db.invoices.status.equals(status));
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where(_db.invoices.invoiceNumber.contains(searchQuery));
    }

    query.orderBy([OrderingTerm.desc(_db.invoices.createdAt)]);
    query.limit(pageSize, offset: offset);

    final rows = await query.get();
    if (rows.isEmpty) {
      return [];
    }

    final invoiceIds = rows.map((r) => r.readTable(_db.invoices).id).toList();
    
    // Fetch all items for these invoices in one query
    final itemRows = await (_db.select(_db.invoiceItems).join([
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
    ])..where(_db.invoiceItems.invoiceId.isIn(invoiceIds))).get();

    final itemsMap = <String, List<domain.InvoiceItem>>{};
    for (final row in itemRows) {
      final item = row.readTable(_db.invoiceItems);
      final product = row.readTableOrNull(_db.products);
      
      final itemMap = _itemRowToMap(item);
      if (product != null) {
        itemMap['product_name'] = product.name;
      }
      
      final entity = InvoiceItemModel.fromMap(itemMap).toEntity();
      itemsMap.putIfAbsent(item.invoiceId, () => []).add(entity);
    }

    return rows.map((row) {
      final invoice = row.readTable(_db.invoices);
      final customer = row.readTableOrNull(_db.customers);
      final supplier = row.readTableOrNull(_db.suppliers);
      
      final map = _rowToMap(invoice);
      if (customer != null) {
        map['customer_name'] = customer.name;
      }
      if (supplier != null) {
        map['supplier_name'] = supplier.name;
      }
      
      return InvoiceModel.fromMap(map).toEntity().copyWith(
        items: itemsMap[invoice.id] ?? [],
      );
    }).toList();
  }

  @override
  Future<domain.Invoice?> getInvoiceById(String id) async {
    final query = _db.select(_db.invoices).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.invoices.supplierId)),
    ])..where(_db.invoices.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }

    final invoice = row.readTable(_db.invoices);
    final customer = row.readTableOrNull(_db.customers);
    final supplier = row.readTableOrNull(_db.suppliers);

    final items = await _getInvoiceItems(invoice.id);
    
    final map = _rowToMap(invoice);
    if (customer != null) {
      map['customer_name'] = customer.name;
    }
    if (supplier != null) {
      map['supplier_name'] = supplier.name;
    }
    
    return InvoiceModel.fromMap(map).toEntity().copyWith(items: items);
  }

  @override
  Future<domain.Invoice> createInvoice(domain.Invoice invoice, List<domain.InvoiceItem> items) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    
    return await _db.transaction(() async {
      await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
        id: id,
        businessId: invoice.businessId,
        customerId: Value(invoice.customerId),
        invoiceNumber: invoice.invoiceNumber,
        status: Value(invoice.status),
        invoiceDate: invoice.invoiceDate.millisecondsSinceEpoch,
        dueDate: invoice.dueDate.millisecondsSinceEpoch,
        subtotal: Value(invoice.subtotal),
        discountPercent: Value(invoice.discountPercent),
        discountAmount: Value(invoice.discountAmount),
        taxPercent: Value(invoice.taxPercent),
        taxAmount: Value(invoice.taxAmount),
        grandTotal: Value(invoice.grandTotal),
        paidAmount: Value(invoice.paidAmount),
        balanceDue: Value(invoice.balanceDue),
        currency: Value(invoice.currency),
        currencySymbol: Value(invoice.currencySymbol),
        exchangeRate: Value(invoice.exchangeRate),
        notes: Value(invoice.notes),
        termsAndConditions: Value(invoice.termsAndConditions),
        templateStyle: Value(invoice.templateStyle),
        isRecurring: Value(invoice.isRecurring),
        recurringInterval: Value(invoice.recurringInterval),
        recurringNextDate: Value(invoice.recurringNextDate?.millisecondsSinceEpoch),
        recurringEndDate: Value(invoice.recurringEndDate?.millisecondsSinceEpoch),
        isPurchaseOrder: Value(invoice.isPurchaseOrder),
        supplierId: Value(invoice.supplierId),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ));

      for (final item in items) {
        await _db.into(_db.invoiceItems).insert(InvoiceItemsCompanion.insert(
          id: const Uuid().v4(),
          invoiceId: id,
          productId: Value(item.productId),
          description: item.description,
          quantity: Value(item.quantity),
          unitPrice: Value(item.unitPrice),
          discountPercent: Value(item.discountPercent),
          discountAmount: Value(item.discountAmount),
          taxPercent: Value(item.taxPercent),
          taxAmount: Value(item.taxAmount),
          subtotal: Value(item.subtotal),
        ));

        if (item.productId != null && invoice.status != 'draft') {
          await _updateInventory(invoice.businessId, item.productId!, -item.quantity, 'invoice', id);
        }
      }

      await _logAudit(invoice.businessId, 'invoice', id, 'create', jsonEncode(items.map((i) => i.description).toList()));

      final created = await getInvoiceById(id);
      return created!;
    });
  }

  @override
  Future<domain.Invoice> updateInvoice(domain.Invoice invoice, List<domain.InvoiceItem> items) async {
    final now = DateTime.now();
    
    return await _db.transaction(() async {
      final oldInvoice = await getInvoiceById(invoice.id);
      
      await (_db.invoices.update()..where((t) => t.id.equals(invoice.id))).write(InvoicesCompanion(
        customerId: Value(invoice.customerId),
        invoiceNumber: Value(invoice.invoiceNumber),
        status: Value(invoice.status),
        invoiceDate: Value(invoice.invoiceDate.millisecondsSinceEpoch),
        dueDate: Value(invoice.dueDate.millisecondsSinceEpoch),
        subtotal: Value(invoice.subtotal),
        discountPercent: Value(invoice.discountPercent),
        discountAmount: Value(invoice.discountAmount),
        taxPercent: Value(invoice.taxPercent),
        taxAmount: Value(invoice.taxAmount),
        grandTotal: Value(invoice.grandTotal),
        paidAmount: Value(invoice.paidAmount),
        balanceDue: Value(invoice.balanceDue),
        currency: Value(invoice.currency),
        currencySymbol: Value(invoice.currencySymbol),
        exchangeRate: Value(invoice.exchangeRate),
        notes: Value(invoice.notes),
        termsAndConditions: Value(invoice.termsAndConditions),
        templateStyle: Value(invoice.templateStyle),
        isRecurring: Value(invoice.isRecurring),
        recurringInterval: Value(invoice.recurringInterval),
        recurringNextDate: Value(invoice.recurringNextDate?.millisecondsSinceEpoch),
        recurringEndDate: Value(invoice.recurringEndDate?.millisecondsSinceEpoch),
        isPurchaseOrder: Value(invoice.isPurchaseOrder),
        supplierId: Value(invoice.supplierId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ));

      // Reverse old inventory impact
      if (oldInvoice != null && oldInvoice.status != 'draft') {
        for (final item in oldInvoice.items) {
          if (item.productId != null) {
            await _updateInventory(invoice.businessId, item.productId!, item.quantity, 'invoice_update_reverse', invoice.id);
          }
        }
      }

      await (_db.invoiceItems.delete()..where((t) => t.invoiceId.equals(invoice.id))).go();
      
      for (final item in items) {
        await _db.into(_db.invoiceItems).insert(InvoiceItemsCompanion.insert(
          id: const Uuid().v4(),
          invoiceId: invoice.id,
          productId: Value(item.productId),
          description: item.description,
          quantity: Value(item.quantity),
          unitPrice: Value(item.unitPrice),
          discountPercent: Value(item.discountPercent),
          discountAmount: Value(item.discountAmount),
          taxPercent: Value(item.taxPercent),
          taxAmount: Value(item.taxAmount),
          subtotal: Value(item.subtotal),
        ));

        if (item.productId != null && invoice.status != 'draft') {
          await _updateInventory(invoice.businessId, item.productId!, -item.quantity, 'invoice', invoice.id);
        }
      }

      await _logAudit(invoice.businessId, 'invoice', invoice.id, 'update', 'Updated invoice items');

      final updated = await getInvoiceById(invoice.id);
      return updated!;
    });
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await (_db.invoices.update()..where((t) => t.id.equals(id))).write(
      InvoicesCompanion(deletedAt: Value(DateTime.now().millisecondsSinceEpoch))
    );
  }

  @override
  Future<void> restoreInvoice(String id) async {
    // Logic for restoring would depend on how deleted items are tracked.
    // Assuming soft delete via deletedAt column.
    await (_db.invoices.update()..where((t) => t.id.equals(id))).write(
      const InvoicesCompanion(deletedAt: Value(null))
    );
  }

  @override
  Future<String> generateInvoiceNumber(String businessId, String prefix) async {
    return await _db.transaction(() async {
      final existing = await (_db.invoiceNumbering.select()
        ..where((t) => t.businessId.equals(businessId))
        ..where((t) => t.prefix.equals(prefix))
        ..where((t) => t.type.equals('invoice'))).getSingleOrNull();

      int nextNumber = 1;
      if (existing != null) {
        nextNumber = existing.lastNumber + 1;
        await (_db.invoiceNumbering.update()..where((t) => t.id.equals(existing.id))).write(
          InvoiceNumberingCompanion(lastNumber: Value(nextNumber))
        );
      } else {
        await _db.into(_db.invoiceNumbering).insert(InvoiceNumberingCompanion.insert(
          id: const Uuid().v4(),
          businessId: businessId,
          prefix: prefix,
          type: 'invoice',
          lastNumber: Value(nextNumber),
        ));
      }

      return '$prefix${nextNumber.toString().padLeft(6, '0')}';
    });
  }

  @override
  Future<Map<String, dynamic>> getInvoiceStats(String businessId) async {
    final rows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();

    int total = 0;
    int paid = 0;
    int overdue = 0;
    int draft = 0;
    double totalRevenue = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final r in rows) {
      total++;
      totalRevenue += r.grandTotal;
      if (r.status == 'paid') {
        paid++;
      } else if (r.status == 'draft') {
        draft++;
      } else if (r.dueDate < now && r.status != 'cancelled') {
        overdue++;
      }
    }

    return {
      'total': total,
      'paid': paid,
      'overdue': overdue,
      'draft': draft,
      'total_revenue': totalRevenue,
    };
  }

  @override
  Future<double> getTotalRevenue(String businessId) async {
    final result = await (_db.invoices.selectOnly()
      ..addColumns([_db.invoices.grandTotal.sum()])
      ..where(_db.invoices.businessId.equals(businessId))
      ..where(_db.invoices.deletedAt.isNull())
      ..where(_db.invoices.status.equals('paid'))).getSingle();
    return result.read(_db.invoices.grandTotal.sum()) ?? 0.0;
  }

  @override
  Future<double> getMonthlyRevenue(String businessId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final result = await (_db.invoices.selectOnly()
      ..addColumns([_db.invoices.grandTotal.sum()])
      ..where(_db.invoices.businessId.equals(businessId))
      ..where(_db.invoices.deletedAt.isNull())
      ..where(_db.invoices.status.equals('paid'))
      ..where(_db.invoices.invoiceDate.isBiggerOrEqualValue(startOfMonth))).getSingle();
    return result.read(_db.invoices.grandTotal.sum()) ?? 0.0;
  }

  @override
  Future<double> getYearlyRevenue(String businessId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
    final result = await (_db.invoices.selectOnly()
      ..addColumns([_db.invoices.grandTotal.sum()])
      ..where(_db.invoices.businessId.equals(businessId))
      ..where(_db.invoices.deletedAt.isNull())
      ..where(_db.invoices.status.equals('paid'))
      ..where(_db.invoices.invoiceDate.isBiggerOrEqualValue(startOfYear))).getSingle();
    return result.read(_db.invoices.grandTotal.sum()) ?? 0.0;
  }

  @override
  Future<List<domain.Invoice>> getRecentInvoices(String businessId, {int limit = 10}) async {
    return getAllInvoices(businessId, pageSize: limit);
  }

  @override
  Future<List<domain.Invoice>> getOverdueInvoices(String businessId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final query = _db.select(_db.invoices).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.invoices.supplierId)),
    ])
      ..where(_db.invoices.businessId.equals(businessId))
      ..where(_db.invoices.deletedAt.isNull())
      ..where(_db.invoices.status.isNotIn(['paid', 'cancelled']))
      ..where(_db.invoices.dueDate.isSmallerThanValue(now))
      ..orderBy([OrderingTerm.desc(_db.invoices.dueDate)]);

    final rows = await query.get();
    return _rowsToEntities(rows);
  }

  @override
  Future<List<domain.Invoice>> getRecurringInvoices(String businessId) async {
    final query = _db.select(_db.invoices).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.invoices.supplierId)),
    ])
      ..where(_db.invoices.businessId.equals(businessId))
      ..where(_db.invoices.isRecurring.equals(true))
      ..where(_db.invoices.deletedAt.isNull());

    final rows = await query.get();
    return _rowsToEntities(rows);
  }

  @override
  Future<void> generateRecurringInvoices() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final recurringInvoices = await (_db.invoices.select()
      ..where((t) => t.isRecurring.equals(true))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => (t.recurringNextDate.isSmallerOrEqualValue(now)) & t.recurringNextDate.isNotNull())).get();

    for (final inv in recurringInvoices) {
      final items = await _getInvoiceItems(inv.id);
      final business = await (_db.businesses.select()..where((t) => t.id.equals(inv.businessId))).getSingle();
      final nextInvoiceNumber = await generateInvoiceNumber(inv.businessId, business.invoicePrefix);
      
      final nextDate = DateTime.fromMillisecondsSinceEpoch(inv.recurringNextDate!);
      DateTime? newNextDate;
      switch (inv.recurringInterval) {
        case 'Daily': newNextDate = nextDate.add(const Duration(days: 1)); break;
        case 'Weekly': newNextDate = nextDate.add(const Duration(days: 7)); break;
        case 'Biweekly': newNextDate = nextDate.add(const Duration(days: 14)); break;
        case 'Monthly': newNextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day); break;
        case 'Quarterly': newNextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day); break;
        case 'Yearly': newNextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day); break;
      }

      if (inv.recurringEndDate != null && newNextDate != null && newNextDate.millisecondsSinceEpoch > inv.recurringEndDate!) {
        newNextDate = null;
      }

      await createInvoice(
        InvoiceModel.fromMap(_rowToMap(inv)).toEntity().copyWith(
          id: const Uuid().v4(),
          invoiceNumber: nextInvoiceNumber,
          invoiceDate: nextDate,
          dueDate: nextDate.add(const Duration(days: 30)),
          status: 'draft',
          isRecurring: false, 
        ),
        items.map((i) => i.copyWith(id: const Uuid().v4())).toList(),
      );

      await (_db.invoices.update()..where((t) => t.id.equals(inv.id))).write(InvoicesCompanion(
        recurringNextDate: Value(newNextDate?.millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRevenueChartData(String businessId, {String period = 'monthly'}) async {
    // For simplicity, keeping the logic similar but optimizing row fetch
    final rows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.status.equals('paid'))).get();

    final Map<String, double> data = {};
    for (final r in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.invoiceDate);
      String key;
      if (period == 'monthly') {
        key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      } else if (period == 'yearly') {
        key = '${date.year}';
      } else {
        key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      data[key] = (data[key] ?? 0) + r.grandTotal;
    }

    return data.entries.map((e) => {'label': e.key, 'value': e.value}).toList()
      ..sort((a, b) => (a['label'] as String).compareTo(b['label'] as String));
  }

  Future<List<domain.Invoice>> _rowsToEntities(List<TypedResult> rows) async {
    if (rows.isEmpty) {
      return [];
    }
    final invoiceIds = rows.map((r) => r.readTable(_db.invoices).id).toList();
    
    final itemRows = await (_db.select(_db.invoiceItems).join([
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
    ])..where(_db.invoiceItems.invoiceId.isIn(invoiceIds))).get();

    final itemsMap = <String, List<domain.InvoiceItem>>{};
    for (final row in itemRows) {
      final item = row.readTable(_db.invoiceItems);
      final product = row.readTableOrNull(_db.products);
      final itemMap = _itemRowToMap(item);
      if (product != null) {
        itemMap['product_name'] = product.name;
      }
      itemsMap.putIfAbsent(item.invoiceId, () => []).add(InvoiceItemModel.fromMap(itemMap).toEntity());
    }

    return rows.map((row) {
      final invoice = row.readTable(_db.invoices);
      final customer = row.readTableOrNull(_db.customers);
      final supplier = row.readTableOrNull(_db.suppliers);
      final map = _rowToMap(invoice);
      if (customer != null) {
        map['customer_name'] = customer.name;
      }
      if (supplier != null) {
        map['supplier_name'] = supplier.name;
      }
      return InvoiceModel.fromMap(map).toEntity().copyWith(items: itemsMap[invoice.id] ?? []);
    }).toList();
  }

  Future<List<domain.InvoiceItem>> _getInvoiceItems(String invoiceId) async {
    final query = _db.select(_db.invoiceItems).join([
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
    ])..where(_db.invoiceItems.invoiceId.equals(invoiceId));

    final rows = await query.get();
    return rows.map((row) {
      final item = row.readTable(_db.invoiceItems);
      final product = row.readTableOrNull(_db.products);
      final map = _itemRowToMap(item);
      if (product != null) {
        map['product_name'] = product.name;
      }
      return InvoiceItemModel.fromMap(map).toEntity();
    }).toList();
  }

  Map<String, dynamic> _rowToMap(Invoice row) {
    return {
      'id': row.id,
      'business_id': row.businessId,
      'customer_id': row.customerId,
      'invoice_number': row.invoiceNumber,
      'status': row.status,
      'invoice_date': row.invoiceDate,
      'due_date': row.dueDate,
      'subtotal': row.subtotal,
      'discount_percent': row.discountPercent,
      'discount_amount': row.discountAmount,
      'tax_percent': row.taxPercent,
      'tax_amount': row.taxAmount,
      'grand_total': row.grandTotal,
      'paid_amount': row.paidAmount,
      'balance_due': row.balanceDue,
      'currency': row.currency,
      'currency_symbol': row.currencySymbol,
      'exchange_rate': row.exchangeRate,
      'notes': row.notes,
      'terms_and_conditions': row.termsAndConditions,
      'template_style': row.templateStyle,
      'is_recurring': row.isRecurring ? 1 : 0,
      'recurring_interval': row.recurringInterval,
      'recurring_next_date': row.recurringNextDate,
      'recurring_end_date': row.recurringEndDate,
      'is_purchase_order': row.isPurchaseOrder ? 1 : 0,
      'supplier_id': row.supplierId,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'deleted_at': row.deletedAt,
    };
  }

  Map<String, dynamic> _itemRowToMap(InvoiceItem row) {
    return {
      'id': row.id,
      'invoice_id': row.invoiceId,
      'product_id': row.productId,
      'description': row.description,
      'quantity': row.quantity,
      'unit_price': row.unitPrice,
      'discount_percent': row.discountPercent,
      'discount_amount': row.discountAmount,
      'tax_percent': row.taxPercent,
      'tax_amount': row.taxAmount,
      'subtotal': row.subtotal,
    };
  }

  Future<void> _updateInventory(String businessId, String productId, double quantityChange, String refType, String refId) async {
    final product = await (_db.products.select()..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product == null) return;

    final newQuantity = product.quantity + quantityChange;
    await (_db.products.update()..where((t) => t.id.equals(productId))).write(ProductsCompanion(
      quantity: Value(newQuantity),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));

    await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
      id: const Uuid().v4(),
      businessId: businessId,
      productId: productId,
      type: quantityChange > 0 ? 'stock_in' : 'stock_out',
      quantity: quantityChange.abs(),
      reason: Value('Invoice Transaction: $refType'),
      referenceType: Value(refType),
      referenceId: Value(refId),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> _logAudit(String businessId, String entityType, String entityId, String action, String changes) async {
    await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
      id: const Uuid().v4(),
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      changes: changes,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}
