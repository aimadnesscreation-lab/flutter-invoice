class Invoice {
  final String id;
  final String businessId;
  final String? customerId;
  final String? customerName;
  final String invoiceNumber;
  final String status;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final double paidAmount;
  final double balanceDue;
  final String currency;
  final String currencySymbol;
  final double exchangeRate;
  final String? notes;
  final String? termsAndConditions;
  final String templateStyle;
  final bool isRecurring;
  final String? recurringInterval;
  final DateTime? recurringNextDate;
  final DateTime? recurringEndDate;
  final bool isPurchaseOrder;
  final String? supplierId;
  final String? supplierName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.businessId,
    this.customerId,
    this.customerName,
    required this.invoiceNumber,
    this.status = 'draft',
    required this.invoiceDate,
    required this.dueDate,
    this.subtotal = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    this.grandTotal = 0.0,
    this.paidAmount = 0.0,
    this.balanceDue = 0.0,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.exchangeRate = 1.0,
    this.notes,
    this.termsAndConditions,
    this.templateStyle = 'modern',
    this.isRecurring = false,
    this.recurringInterval,
    this.recurringNextDate,
    this.recurringEndDate,
    this.isPurchaseOrder = false,
    this.supplierId,
    this.supplierName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.items = const [],
  });

  Invoice copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? invoiceNumber,
    String? status,
    DateTime? invoiceDate,
    DateTime? dueDate,
    double? subtotal,
    double? discountPercent,
    double? discountAmount,
    double? taxPercent,
    double? taxAmount,
    double? grandTotal,
    double? paidAmount,
    double? balanceDue,
    String? currency,
    String? currencySymbol,
    double? exchangeRate,
    String? notes,
    String? termsAndConditions,
    String? templateStyle,
    bool? isRecurring,
    String? recurringInterval,
    DateTime? recurringNextDate,
    DateTime? recurringEndDate,
    bool? isPurchaseOrder,
    String? supplierId,
    String? supplierName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      subtotal: subtotal ?? this.subtotal,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      templateStyle: templateStyle ?? this.templateStyle,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      recurringNextDate: recurringNextDate ?? this.recurringNextDate,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      isPurchaseOrder: isPurchaseOrder ?? this.isPurchaseOrder,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      items: items ?? this.items,
    );
  }
}

class InvoiceItem {
  final String id;
  final String invoiceId;
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

  InvoiceItem({
    required this.id,
    required this.invoiceId,
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

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
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
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
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
