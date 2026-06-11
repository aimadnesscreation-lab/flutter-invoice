import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/estimate_model.dart';
import 'package:invoice_pro/domain/entities/estimate.dart' as domain;
import 'package:invoice_pro/domain/repositories/estimate_repository.dart';

class EstimateRepositoryImpl implements EstimateRepository {
  final AppDatabase _db;

  EstimateRepositoryImpl(this._db);

  @override
  Future<List<domain.Estimate>> getAllEstimates(String businessId, {String? status, String? searchQuery, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    final query = _db.select(_db.estimates).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.estimates.customerId)),
    ])
      ..where(_db.estimates.businessId.equals(businessId))
      ..where(_db.estimates.deletedAt.isNull());

    if (status != null && status.isNotEmpty) {
      query.where(_db.estimates.status.equals(status));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final term = '%$searchQuery%';
      query.where(_db.estimates.estimateNumber.like(term));
    }

    query.orderBy([OrderingTerm(expression: _db.estimates.createdAt, mode: OrderingMode.desc)]);
    query.limit(pageSize, offset: offset);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final estimateIds = rows.map((r) => r.readTable(_db.estimates).id).toList();
    
    // Fetch all items for these estimates
    final itemRows = await (_db.select(_db.estimateItems).join([
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.estimateItems.productId)),
    ])..where(_db.estimateItems.estimateId.isIn(estimateIds))).get();

    final itemsMap = <String, List<domain.EstimateItem>>{};
    for (final row in itemRows) {
      final item = row.readTable(_db.estimateItems);
      final product = row.readTableOrNull(_db.products);
      final map = _itemRowToMap(item);
      if (product != null) map['product_name'] = product.name;
      itemsMap.putIfAbsent(item.estimateId, () => []).add(EstimateItemModel.fromMap(map).toEntity());
    }

    return rows.map((row) {
      final estimate = row.readTable(_db.estimates);
      final customer = row.readTableOrNull(_db.customers);
      final map = _rowToMap(estimate);
      if (customer != null) map['customer_name'] = customer.name;
      return EstimateModel.fromMap(map).toEntity().copyWith(items: itemsMap[estimate.id] ?? []);
    }).toList();
  }

  @override
  Future<domain.Estimate?> getEstimateById(String id) async {
    final query = _db.select(_db.estimates).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.estimates.customerId)),
    ])..where(_db.estimates.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final estimate = row.readTable(_db.estimates);
    final customer = row.readTableOrNull(_db.customers);
    final map = _rowToMap(estimate);
    if (customer != null) map['customer_name'] = customer.name;

    final items = await _getEstimateItems(estimate.id);
    return EstimateModel.fromMap(map).toEntity().copyWith(items: items);
  }

  @override
  Future<domain.Estimate> createEstimate(domain.Estimate estimate, List<domain.EstimateItem> items) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    
    return await _db.transaction(() async {
      await _db.into(_db.estimates).insert(EstimatesCompanion.insert(
        id: id,
        businessId: estimate.businessId,
        customerId: Value(estimate.customerId),
        estimateNumber: estimate.estimateNumber,
        status: Value(estimate.status),
        estimateDate: estimate.estimateDate.millisecondsSinceEpoch,
        expiryDate: estimate.expiryDate.millisecondsSinceEpoch,
        subtotal: Value(estimate.subtotal),
        discountPercent: Value(estimate.discountPercent),
        discountAmount: Value(estimate.discountAmount),
        taxPercent: Value(estimate.taxPercent),
        taxAmount: Value(estimate.taxAmount),
        grandTotal: Value(estimate.grandTotal),
        currency: Value(estimate.currency),
        currencySymbol: Value(estimate.currencySymbol),
        notes: Value(estimate.notes),
        termsAndConditions: Value(estimate.termsAndConditions),
        convertedInvoiceId: Value(estimate.convertedInvoiceId),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ));

      for (final item in items) {
        await _db.into(_db.estimateItems).insert(EstimateItemsCompanion.insert(
          id: const Uuid().v4(),
          estimateId: id,
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
      }

      final created = await getEstimateById(id);
      return created!;
    });
  }

  @override
  Future<domain.Estimate> updateEstimate(domain.Estimate estimate, List<domain.EstimateItem> items) async {
    final now = DateTime.now();
    
    return await _db.transaction(() async {
      await (_db.estimates.update()
        ..where((t) => t.id.equals(estimate.id))).write(EstimatesCompanion(
          customerId: Value(estimate.customerId),
          estimateNumber: Value(estimate.estimateNumber),
          status: Value(estimate.status),
          estimateDate: Value(estimate.estimateDate.millisecondsSinceEpoch),
          expiryDate: Value(estimate.expiryDate.millisecondsSinceEpoch),
          subtotal: Value(estimate.subtotal),
          discountPercent: Value(estimate.discountPercent),
          discountAmount: Value(estimate.discountAmount),
          taxPercent: Value(estimate.taxPercent),
          taxAmount: Value(estimate.taxAmount),
          grandTotal: Value(estimate.grandTotal),
          currency: Value(estimate.currency),
          currencySymbol: Value(estimate.currencySymbol),
          notes: Value(estimate.notes),
          termsAndConditions: Value(estimate.termsAndConditions),
          convertedInvoiceId: Value(estimate.convertedInvoiceId),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ));

      await (_db.estimateItems.delete()
        ..where((t) => t.estimateId.equals(estimate.id))).go();
        
      for (final item in items) {
        await _db.into(_db.estimateItems).insert(EstimateItemsCompanion.insert(
          id: const Uuid().v4(),
          estimateId: estimate.id,
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
      }

      final updated = await getEstimateById(estimate.id);
      return updated!;
    });
  }

  @override
  Future<void> deleteEstimate(String id) async {
    await (_db.estimates.update()
      ..where((t) => t.id.equals(id))).write(EstimatesCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
  }

  @override
  Future<String> generateEstimateNumber(String businessId, String prefix) async {
    return await _db.transaction(() async {
      final query = _db.select(_db.invoiceNumbering)
        ..where((t) => t.businessId.equals(businessId))
        ..where((t) => t.type.equals('estimate'))
        ..where((t) => t.prefix.equals(prefix));
      
      final existing = await query.getSingleOrNull();
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
          type: 'estimate',
          lastNumber: Value(nextNumber),
        ));
      }

      return '$prefix${nextNumber.toString().padLeft(6, '0')}';
    });
  }

  @override
  Future<String?> convertEstimateToInvoice(String estimateId) async {
    final estimate = await getEstimateById(estimateId);
    if (estimate == null) return null;

    final invoiceId = const Uuid().v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      // Create invoice
      await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
        id: invoiceId,
        businessId: estimate.businessId,
        customerId: Value(estimate.customerId),
        invoiceNumber: 'INV-${estimate.estimateNumber.replaceAll(RegExp(r'[^0-9]'), '')}',
        status: const Value('draft'),
        invoiceDate: now.millisecondsSinceEpoch,
        dueDate: now.add(const Duration(days: 30)).millisecondsSinceEpoch,
        subtotal: Value(estimate.subtotal),
        discountPercent: Value(estimate.discountPercent),
        discountAmount: Value(estimate.discountAmount),
        taxPercent: Value(estimate.taxPercent),
        taxAmount: Value(estimate.taxAmount),
        grandTotal: Value(estimate.grandTotal),
        currency: Value(estimate.currency),
        currencySymbol: Value(estimate.currencySymbol),
        notes: Value(estimate.notes),
        termsAndConditions: Value(estimate.termsAndConditions),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ));

      // Create invoice items
      for (final item in estimate.items) {
        await _db.into(_db.invoiceItems).insert(InvoiceItemsCompanion.insert(
          id: const Uuid().v4(),
          invoiceId: invoiceId,
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
      }

      // Mark estimate as converted
      await (_db.estimates.update()
        ..where((t) => t.id.equals(estimateId))).write(EstimatesCompanion(
          status: const Value('accepted'),
          convertedInvoiceId: Value(invoiceId),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ));
    });

    return invoiceId;
  }

  Future<List<domain.EstimateItem>> _getEstimateItems(String estimateId) async {
    final query = _db.select(_db.estimateItems).join([
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.estimateItems.productId)),
    ])..where(_db.estimateItems.estimateId.equals(estimateId));

    final rows = await query.get();
    return rows.map((row) {
      final item = row.readTable(_db.estimateItems);
      final product = row.readTableOrNull(_db.products);
      final map = _itemRowToMap(item);
      if (product != null) map['product_name'] = product.name;
      return EstimateItemModel.fromMap(map).toEntity();
    }).toList();
  }

  Map<String, dynamic> _rowToMap(Estimate row) {
    return {
      'id': row.id,
      'business_id': row.businessId,
      'customer_id': row.customerId,
      'customer_name': null,
      'estimate_number': row.estimateNumber,
      'status': row.status,
      'estimate_date': row.estimateDate,
      'expiry_date': row.expiryDate,
      'subtotal': row.subtotal,
      'discount_percent': row.discountPercent,
      'discount_amount': row.discountAmount,
      'tax_percent': row.taxPercent,
      'tax_amount': row.taxAmount,
      'grand_total': row.grandTotal,
      'currency': row.currency,
      'currency_symbol': row.currencySymbol,
      'notes': row.notes,
      'terms_and_conditions': row.termsAndConditions,
      'converted_invoice_id': row.convertedInvoiceId,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'deleted_at': row.deletedAt,
    };
  }

  Map<String, dynamic> _itemRowToMap(EstimateItem row) {
    return {
      'id': row.id,
      'estimate_id': row.estimateId,
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
