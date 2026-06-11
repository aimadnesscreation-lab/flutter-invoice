class Estimate {
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
  final List<EstimateItem> items;

  Estimate({
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

  Estimate copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? estimateNumber,
    String? status,
    DateTime? estimateDate,
    DateTime? expiryDate,
    double? subtotal,
    double? discountPercent,
    double? discountAmount,
    double? taxPercent,
    double? taxAmount,
    double? grandTotal,
    String? currency,
    String? currencySymbol,
    String? notes,
    String? termsAndConditions,
    String? convertedInvoiceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<EstimateItem>? items,
  }) {
    return Estimate(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      estimateNumber: estimateNumber ?? this.estimateNumber,
      status: status ?? this.status,
      estimateDate: estimateDate ?? this.estimateDate,
      expiryDate: expiryDate ?? this.expiryDate,
      subtotal: subtotal ?? this.subtotal,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      convertedInvoiceId: convertedInvoiceId ?? this.convertedInvoiceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      items: items ?? this.items,
    );
  }
}

class EstimateItem {
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

  EstimateItem({
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

  EstimateItem copyWith({
    String? id,
    String? estimateId,
    String? productId,
    String? productName,
    String? description,
    double? quantity,
    double? unitPrice,
    double? discountPercent,
    double? discountAmount,
    double? taxPercent,
    double? taxAmount,
    double? subtotal,
  }) {
    return EstimateItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
