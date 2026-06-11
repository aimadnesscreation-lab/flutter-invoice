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
    var allRows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    var rows = allRows;

    if (status != null) {
      rows = rows.where((r) => r.status == status).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      rows = rows.where((r) =>
        r.invoiceNumber.toLowerCase().contains(query)
      ).toList();
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paged = rows.skip(offset).take(pageSize).toList();

    final result = <domain.Invoice>[];
    for (final row in paged) {
      final items = await _getInvoiceItems(row.id);
      result.add(await _toEntity(row, items: items));
    }
    return result;
  }

  @override
  Future<domain.Invoice?> getInvoiceById(String id) async {
    final row = await (_db.invoices.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final items = await _getInvoiceItems(row.id);
    return _toEntity(row, items: items);
  }

  @override
  Future<domain.Invoice> createInvoice(domain.Invoice invoice, List<domain.InvoiceItem> items) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final model = InvoiceModel(
      id: id,
      businessId: invoice.businessId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceNumber: invoice.invoiceNumber,
      status: invoice.status,
      invoiceDate: invoice.invoiceDate,
      dueDate: invoice.dueDate,
      subtotal: invoice.subtotal,
      discountPercent: invoice.discountPercent,
      discountAmount: invoice.discountAmount,
      taxPercent: invoice.taxPercent,
      taxAmount: invoice.taxAmount,
      grandTotal: invoice.grandTotal,
      paidAmount: invoice.paidAmount,
      balanceDue: invoice.balanceDue,
      currency: invoice.currency,
      currencySymbol: invoice.currencySymbol,
      exchangeRate: invoice.exchangeRate,
      notes: invoice.notes,
      termsAndConditions: invoice.termsAndConditions,
      templateStyle: invoice.templateStyle,
      isRecurring: invoice.isRecurring,
      recurringInterval: invoice.recurringInterval,
      recurringNextDate: invoice.recurringNextDate,
      recurringEndDate: invoice.recurringEndDate,
      isPurchaseOrder: invoice.isPurchaseOrder,
      supplierId: invoice.supplierId,
      supplierName: invoice.supplierName,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
      id: model.id,
      businessId: model.businessId,
      customerId: Value(model.customerId),
      invoiceNumber: model.invoiceNumber,
      status: Value(model.status),
      invoiceDate: model.invoiceDate.millisecondsSinceEpoch,
      dueDate: model.dueDate.millisecondsSinceEpoch,
      subtotal: Value(model.subtotal),
      discountPercent: Value(model.discountPercent),
      discountAmount: Value(model.discountAmount),
      taxPercent: Value(model.taxPercent),
      taxAmount: Value(model.taxAmount),
      grandTotal: Value(model.grandTotal),
      paidAmount: Value(model.paidAmount),
      balanceDue: Value(model.balanceDue),
      currency: Value(model.currency),
      currencySymbol: Value(model.currencySymbol),
      exchangeRate: Value(model.exchangeRate),
      notes: Value(model.notes),
      termsAndConditions: Value(model.termsAndConditions),
      templateStyle: Value(model.templateStyle),
      isRecurring: Value(model.isRecurring),
      recurringInterval: Value(model.recurringInterval),
      recurringNextDate: Value(model.recurringNextDate?.millisecondsSinceEpoch),
      recurringEndDate: Value(model.recurringEndDate?.millisecondsSinceEpoch),
      isPurchaseOrder: Value(model.isPurchaseOrder),
      supplierId: Value(model.supplierId),
      createdAt: model.createdAt.millisecondsSinceEpoch,
      updatedAt: model.updatedAt.millisecondsSinceEpoch,
    ));

    for (final item in items) {
      final itemModel = InvoiceItemModel(
        id: const Uuid().v4(),
        invoiceId: id,
        productId: item.productId,
        productName: item.productName,
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountPercent: item.discountPercent,
        discountAmount: item.discountAmount,
        taxPercent: item.taxPercent,
        taxAmount: item.taxAmount,
        subtotal: item.subtotal,
      );
      await _db.into(_db.invoiceItems).insert(InvoiceItemsCompanion.insert(
        id: itemModel.id,
        invoiceId: itemModel.invoiceId,
        productId: Value(itemModel.productId),
        description: itemModel.description,
        quantity: Value(itemModel.quantity),
        unitPrice: Value(itemModel.unitPrice),
        discountPercent: Value(itemModel.discountPercent),
        discountAmount: Value(itemModel.discountAmount),
        taxPercent: Value(itemModel.taxPercent),
        taxAmount: Value(itemModel.taxAmount),
        subtotal: Value(itemModel.subtotal),
      ));
    }

    return model.toEntity().copyWith(items: items);
  }

  @override
  Future<domain.Invoice> updateInvoice(domain.Invoice invoice, List<domain.InvoiceItem> items) async {
    final now = DateTime.now();
    final model = InvoiceModel.fromEntity(invoice.copyWith(updatedAt: now));
    await (_db.invoices.update()
      ..where((t) => t.id.equals(model.id))).write(InvoicesCompanion(
        customerId: Value(model.customerId),
        invoiceNumber: Value(model.invoiceNumber),
        status: Value(model.status),
        invoiceDate: Value(model.invoiceDate.millisecondsSinceEpoch),
        dueDate: Value(model.dueDate.millisecondsSinceEpoch),
        subtotal: Value(model.subtotal),
        discountPercent: Value(model.discountPercent),
        discountAmount: Value(model.discountAmount),
        taxPercent: Value(model.taxPercent),
        taxAmount: Value(model.taxAmount),
        grandTotal: Value(model.grandTotal),
        paidAmount: Value(model.paidAmount),
        balanceDue: Value(model.balanceDue),
        currency: Value(model.currency),
        currencySymbol: Value(model.currencySymbol),
        exchangeRate: Value(model.exchangeRate),
        notes: Value(model.notes),
        termsAndConditions: Value(model.termsAndConditions),
        templateStyle: Value(model.templateStyle),
        isRecurring: Value(model.isRecurring),
        recurringInterval: Value(model.recurringInterval),
        recurringNextDate: Value(model.recurringNextDate?.millisecondsSinceEpoch),
        recurringEndDate: Value(model.recurringEndDate?.millisecondsSinceEpoch),
        isPurchaseOrder: Value(model.isPurchaseOrder),
        supplierId: Value(model.supplierId),
        updatedAt: Value(model.updatedAt.millisecondsSinceEpoch),
      ));

    await (_db.invoiceItems.delete()
      ..where((t) => t.invoiceId.equals(model.id))).go();
    for (final item in items) {
      final itemModel = InvoiceItemModel(
        id: const Uuid().v4(),
        invoiceId: model.id,
        productId: item.productId,
        productName: item.productName,
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountPercent: item.discountPercent,
        discountAmount: item.discountAmount,
        taxPercent: item.taxPercent,
        taxAmount: item.taxAmount,
        subtotal: item.subtotal,
      );
      await _db.into(_db.invoiceItems).insert(InvoiceItemsCompanion.insert(
        id: itemModel.id,
        invoiceId: itemModel.invoiceId,
        productId: Value(itemModel.productId),
        description: itemModel.description,
        quantity: Value(itemModel.quantity),
        unitPrice: Value(itemModel.unitPrice),
        discountPercent: Value(itemModel.discountPercent),
        discountAmount: Value(itemModel.discountAmount),
        taxPercent: Value(itemModel.taxPercent),
        taxAmount: Value(itemModel.taxAmount),
        subtotal: Value(itemModel.subtotal),
      ));
    }

    return model.toEntity().copyWith(items: items);
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await (_db.invoiceItems.delete()
      ..where((t) => t.invoiceId.equals(id))).go();
    await (_db.invoices.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> restoreInvoice(String id) async {}

  @override
  Future<String> generateInvoiceNumber(String businessId, String prefix) async {
    final rows = await (_db.invoiceNumbering.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.prefix.equals(prefix))
      ..where((t) => t.type.equals('invoice'))).get();
    final existing = rows.isNotEmpty ? rows.first : null;

    int nextNumber = 1;
    if (existing != null) {
      nextNumber = existing.lastNumber + 1;
      await (_db.invoiceNumbering.delete()
        ..where((t) => t.id.equals(existing.id))).go();
    }

    await _db.into(_db.invoiceNumbering).insert(InvoiceNumberingCompanion.insert(
      id: const Uuid().v4(),
      businessId: businessId,
      prefix: prefix,
      type: 'invoice',
      lastNumber: Value(nextNumber),
    ));

    return '$prefix${nextNumber.toString().padLeft(6, '0')}';
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

    for (final r in rows) {
      total++;
      totalRevenue += r.grandTotal;
      if (r.status == 'paid') paid++;
      if (r.status == 'overdue') overdue++;
      if (r.status == 'draft') draft++;
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
    final rows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.status.equals('paid'))).get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.grandTotal);
  }

  @override
  Future<double> getMonthlyRevenue(String businessId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final rows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.status.equals('paid'))).get();
    return rows
        .where((r) => r.invoiceDate >= startOfMonth)
        .fold<double>(0.0, (sum, r) => sum + r.grandTotal);
  }

  @override
  Future<double> getYearlyRevenue(String businessId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
    final rows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.status.equals('paid'))).get();
    return rows
        .where((r) => r.invoiceDate >= startOfYear)
        .fold<double>(0.0, (sum, r) => sum + r.grandTotal);
  }

  @override
  Future<List<domain.Invoice>> getRecentInvoices(String businessId, {int limit = 10}) async {
    final rows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(limit)).get();

    final result = <domain.Invoice>[];
    for (final row in rows) {
      final items = await _getInvoiceItems(row.id);
      result.add(await _toEntity(row, items: items));
    }
    return result;
  }

  @override
  Future<List<domain.Invoice>> getOverdueInvoices(String businessId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    var rows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    rows = rows.where((r) =>
      r.status != 'paid' &&
      r.status != 'cancelled' &&
      r.dueDate < now
    ).toList();

    final result = <domain.Invoice>[];
    for (final row in rows) {
      final items = await _getInvoiceItems(row.id);
      result.add(await _toEntity(row, items: items));
    }
    return result;
  }

  @override
  Future<List<domain.Invoice>> getRecurringInvoices(String businessId) async {
    final rows = await (_db.invoices.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.isRecurring.equals(true))
      ..where((t) => t.deletedAt.isNull())).get();

    final result = <domain.Invoice>[];
    for (final row in rows) {
      final items = await _getInvoiceItems(row.id);
      result.add(await _toEntity(row, items: items));
    }
    return result;
  }

  @override
  Future<void> generateRecurringInvoices() async {}

  @override
  Future<List<Map<String, dynamic>>> getRevenueChartData(String businessId, {String period = 'monthly'}) async {
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

  Future<domain.Invoice> _toEntity(Invoice row, {List<domain.InvoiceItem> items = const []}) async {
    final map = _rowToMap(row);
    // Populate denormalized fields from related tables
    if (row.customerId != null) {
      final customer = await (_db.customers.select()
        ..where((t) => t.id.equals(row.customerId!))).getSingleOrNull();
      if (customer != null) {
        map['customer_name'] = customer.name;
      }
    }
    if (row.supplierId != null) {
      final supplier = await (_db.suppliers.select()
        ..where((t) => t.id.equals(row.supplierId!))).getSingleOrNull();
      if (supplier != null) {
        map['supplier_name'] = supplier.name;
      }
    }
    return InvoiceModel.fromMap(map).toEntity().copyWith(items: items);
  }

  Future<List<domain.InvoiceItem>> _getInvoiceItems(String invoiceId) async {
    final rows = await (_db.invoiceItems.select()
      ..where((t) => t.invoiceId.equals(invoiceId))).get();
    final result = <domain.InvoiceItem>[];
    for (final r in rows) {
      final map = _itemRowToMap(r);
      // Populate product_name from products table
      if (r.productId != null) {
        final product = await (_db.products.select()
          ..where((t) => t.id.equals(r.productId!))).getSingleOrNull();
        if (product != null) {
          map['product_name'] = product.name;
        }
      }
      result.add(InvoiceItemModel.fromMap(map).toEntity());
    }
    return result;
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
      'customer_name': null,
      'supplier_name': null,
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
      'product_name': null,
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
}
