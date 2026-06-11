import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/estimate_model.dart';
import 'package:invoice_pro/domain/entities/estimate.dart' as domain;
import 'package:invoice_pro/domain/repositories/estimate_repository.dart';

class EstimateRepositoryImpl implements EstimateRepository {
  final AppDatabase _db;
  final Map<String, int> _counters = {};

  EstimateRepositoryImpl(this._db);

  @override
  Future<List<domain.Estimate>> getAllEstimates(String businessId, {String? status, String? searchQuery, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    var allRows = await (_db.estimates.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    var rows = allRows;

    if (status != null) {
      rows = rows.where((r) => r.status == status).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      rows = rows.where((r) => r.estimateNumber.toLowerCase().contains(query)).toList();
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paged = rows.skip(offset).take(pageSize).toList();

    final result = <domain.Estimate>[];
    for (final row in paged) {
      final items = await _getEstimateItems(row.id);
      result.add(await _toEntity(row, items: items));
    }
    return result;
  }

  @override
  Future<domain.Estimate?> getEstimateById(String id) async {
    final row = await (_db.estimates.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final items = await _getEstimateItems(row.id);
    return _toEntity(row, items: items);
  }

  @override
  Future<domain.Estimate> createEstimate(domain.Estimate estimate, List<domain.EstimateItem> items) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final model = EstimateModel(
      id: id,
      businessId: estimate.businessId,
      customerId: estimate.customerId,
      customerName: estimate.customerName,
      estimateNumber: estimate.estimateNumber,
      status: estimate.status,
      estimateDate: estimate.estimateDate,
      expiryDate: estimate.expiryDate,
      subtotal: estimate.subtotal,
      discountPercent: estimate.discountPercent,
      discountAmount: estimate.discountAmount,
      taxPercent: estimate.taxPercent,
      taxAmount: estimate.taxAmount,
      grandTotal: estimate.grandTotal,
      currency: estimate.currency,
      currencySymbol: estimate.currencySymbol,
      notes: estimate.notes,
      termsAndConditions: estimate.termsAndConditions,
      convertedInvoiceId: estimate.convertedInvoiceId,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.estimates).insert(EstimatesCompanion.insert(
      id: model.id,
      businessId: model.businessId,
      customerId: Value(model.customerId),
      estimateNumber: model.estimateNumber,
      status: Value(model.status),
      estimateDate: model.estimateDate.millisecondsSinceEpoch,
      expiryDate: model.expiryDate.millisecondsSinceEpoch,
      subtotal: Value(model.subtotal),
      discountPercent: Value(model.discountPercent),
      discountAmount: Value(model.discountAmount),
      taxPercent: Value(model.taxPercent),
      taxAmount: Value(model.taxAmount),
      grandTotal: Value(model.grandTotal),
      currency: Value(model.currency),
      currencySymbol: Value(model.currencySymbol),
      notes: Value(model.notes),
      termsAndConditions: Value(model.termsAndConditions),
      convertedInvoiceId: Value(model.convertedInvoiceId),
      createdAt: model.createdAt.millisecondsSinceEpoch,
      updatedAt: model.updatedAt.millisecondsSinceEpoch,
    ));

    for (final item in items) {
      final itemModel = EstimateItemModel(
        id: const Uuid().v4(),
        estimateId: id,
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
      await _db.into(_db.estimateItems).insert(EstimateItemsCompanion.insert(
        id: itemModel.id,
        estimateId: itemModel.estimateId,
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
  Future<domain.Estimate> updateEstimate(domain.Estimate estimate, List<domain.EstimateItem> items) async {
    final now = DateTime.now();
    final model = EstimateModel.fromEntity(estimate.copyWith(updatedAt: now));
    await (_db.estimates.update()
      ..where((t) => t.id.equals(model.id))).write(EstimatesCompanion(
        customerId: Value(model.customerId),
        estimateNumber: Value(model.estimateNumber),
        status: Value(model.status),
        estimateDate: Value(model.estimateDate.millisecondsSinceEpoch),
        expiryDate: Value(model.expiryDate.millisecondsSinceEpoch),
        subtotal: Value(model.subtotal),
        discountPercent: Value(model.discountPercent),
        discountAmount: Value(model.discountAmount),
        taxPercent: Value(model.taxPercent),
        taxAmount: Value(model.taxAmount),
        grandTotal: Value(model.grandTotal),
        currency: Value(model.currency),
        currencySymbol: Value(model.currencySymbol),
        notes: Value(model.notes),
        termsAndConditions: Value(model.termsAndConditions),
        convertedInvoiceId: Value(model.convertedInvoiceId),
        updatedAt: Value(model.updatedAt.millisecondsSinceEpoch),
      ));

    await (_db.estimateItems.delete()
      ..where((t) => t.estimateId.equals(model.id))).go();
    for (final item in items) {
      final itemModel = EstimateItemModel(
        id: const Uuid().v4(),
        estimateId: model.id,
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
      await _db.into(_db.estimateItems).insert(EstimateItemsCompanion.insert(
        id: itemModel.id,
        estimateId: itemModel.estimateId,
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
  Future<void> deleteEstimate(String id) async {
    await (_db.estimateItems.delete()
      ..where((t) => t.estimateId.equals(id))).go();
    await (_db.estimates.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<String> generateEstimateNumber(String businessId, String prefix) async {
    _counters[businessId] = (_counters[businessId] ?? 0) + 1;
    return '$prefix${_counters[businessId]!.toString().padLeft(6, '0')}';
  }

  @override
  Future<String?> convertEstimateToInvoice(String estimateId) async {
    // This would create an invoice from the estimate
    return null;
  }

  Future<domain.Estimate> _toEntity(Estimate row, {List<domain.EstimateItem> items = const []}) async {
    final map = _rowToMap(row);
    // Populate denormalized fields from related tables
    if (row.customerId != null) {
      final customer = await (_db.customers.select()
        ..where((t) => t.id.equals(row.customerId!))).getSingleOrNull();
      if (customer != null) {
        map['customer_name'] = customer.name;
      }
    }
    return EstimateModel.fromMap(map).toEntity().copyWith(items: items);
  }

  Future<List<domain.EstimateItem>> _getEstimateItems(String estimateId) async {
    final rows = await (_db.estimateItems.select()
      ..where((t) => t.estimateId.equals(estimateId))).get();
    final result = <domain.EstimateItem>[];
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
      result.add(EstimateItemModel.fromMap(map).toEntity());
    }
    return result;
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
