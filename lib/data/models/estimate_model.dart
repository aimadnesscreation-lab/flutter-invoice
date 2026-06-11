import 'package:invoice_pro/domain/entities/estimate.dart';

class EstimateModel {
  final String id;
  final String businessId;
  final String? customerId;
  final String? customerName;
  final String estimateNumber;
  final String status;
  final DateTime estimateDate;
  final DateTime expiryDate;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final String currency;
  final String currencySymbol;
  final String? notes;
  final String? termsAndConditions;
  final String? convertedInvoiceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<EstimateItemModel> items;

  EstimateModel({
    required this.id,
    required this.businessId,
    this.customerId,
    this.customerName,
    required this.estimateNumber,
    this.status = 'draft',
    required this.estimateDate,
    required this.expiryDate,
    this.subtotal = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    this.grandTotal = 0.0,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.notes,
    this.termsAndConditions,
    this.convertedInvoiceId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.items = const [],
  });

  factory EstimateModel.fromMap(Map<String, dynamic> map) {
    return EstimateModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      estimateNumber: map['estimate_number'] as String,
      status: map['status'] as String? ?? 'draft',
      estimateDate: DateTime.fromMillisecondsSinceEpoch(map['estimate_date'] as int),
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiry_date'] as int),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (map['tax_percent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      currencySymbol: map['currency_symbol'] as String? ?? '\$',
      notes: map['notes'] as String?,
      termsAndConditions: map['terms_and_conditions'] as String?,
      convertedInvoiceId: map['converted_invoice_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int) : null,
      items: map['items'] != null ? (map['items'] as List).map((e) => EstimateItemModel.fromMap(e as Map<String, dynamic>)).toList() : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'customer_name': customerName,
      'estimate_number': estimateNumber,
      'status': status,
      'estimate_date': estimateDate.millisecondsSinceEpoch,
      'expiry_date': expiryDate.millisecondsSinceEpoch,
      'subtotal': subtotal,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'notes': notes,
      'terms_and_conditions': termsAndConditions,
      'converted_invoice_id': convertedInvoiceId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
    };
  }

  Estimate toEntity() {
    return Estimate(
      id: id,
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      estimateNumber: estimateNumber,
      status: status,
      estimateDate: estimateDate,
      expiryDate: expiryDate,
      subtotal: subtotal,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      currency: currency,
      currencySymbol: currencySymbol,
      notes: notes,
      termsAndConditions: termsAndConditions,
      convertedInvoiceId: convertedInvoiceId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      items: items.map((e) => e.toEntity()).toList(),
    );
  }

  factory EstimateModel.fromEntity(Estimate entity) {
    return EstimateModel(
      id: entity.id,
      businessId: entity.businessId,
      customerId: entity.customerId,
      customerName: entity.customerName,
      estimateNumber: entity.estimateNumber,
      status: entity.status,
      estimateDate: entity.estimateDate,
      expiryDate: entity.expiryDate,
      subtotal: entity.subtotal,
      discountPercent: entity.discountPercent,
      discountAmount: entity.discountAmount,
      taxPercent: entity.taxPercent,
      taxAmount: entity.taxAmount,
      grandTotal: entity.grandTotal,
      currency: entity.currency,
      currencySymbol: entity.currencySymbol,
      notes: entity.notes,
      termsAndConditions: entity.termsAndConditions,
      convertedInvoiceId: entity.convertedInvoiceId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      items: entity.items.map((e) => EstimateItemModel.fromEntity(e)).toList(),
    );
  }
}

class EstimateItemModel {
  final String id;
  final String estimateId;
  final String? productId;
  final String? productName;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double subtotal;

  EstimateItemModel({
    required this.id,
    required this.estimateId,
    this.productId,
    this.productName,
    required this.description,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    this.subtotal = 0.0,
  });

  factory EstimateItemModel.fromMap(Map<String, dynamic> map) {
    return EstimateItemModel(
      id: map['id'] as String,
      estimateId: map['estimate_id'] as String,
      productId: map['product_id'] as String?,
      productName: map['product_name'] as String?,
      description: map['description'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (map['tax_percent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimate_id': estimateId,
      'product_id': productId,
      'product_name': productName,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'subtotal': subtotal,
    };
  }

  EstimateItem toEntity() {
    return EstimateItem(
      id: id,
      estimateId: estimateId,
      productId: productId,
      productName: productName,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      subtotal: subtotal,
    );
  }

  factory EstimateItemModel.fromEntity(EstimateItem entity) {
    return EstimateItemModel(
      id: entity.id,
      estimateId: entity.estimateId,
      productId: entity.productId,
      productName: entity.productName,
      description: entity.description,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      discountPercent: entity.discountPercent,
      discountAmount: entity.discountAmount,
      taxPercent: entity.taxPercent,
      taxAmount: entity.taxAmount,
      subtotal: entity.subtotal,
    );
  }
}
