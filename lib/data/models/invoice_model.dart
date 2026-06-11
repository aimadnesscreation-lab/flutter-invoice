import 'dart:convert';
import 'package:invoice_pro/domain/entities/invoice.dart';

class InvoiceModel {
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
  final List<InvoiceItemModel> items;

  InvoiceModel({
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

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      invoiceNumber: map['invoice_number'] as String,
      status: map['status'] as String? ?? 'draft',
      invoiceDate: DateTime.fromMillisecondsSinceEpoch(map['invoice_date'] as int),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (map['tax_percent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      currencySymbol: map['currency_symbol'] as String? ?? '\$',
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      notes: map['notes'] as String?,
      termsAndConditions: map['terms_and_conditions'] as String?,
      templateStyle: map['template_style'] as String? ?? 'modern',
      isRecurring: map['is_recurring'] == 1 || map['is_recurring'] == true,
      recurringInterval: map['recurring_interval'] as String?,
      recurringNextDate: map['recurring_next_date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['recurring_next_date'] as int) : null,
      recurringEndDate: map['recurring_end_date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['recurring_end_date'] as int) : null,
      isPurchaseOrder: map['is_purchase_order'] == 1 || map['is_purchase_order'] == true,
      supplierId: map['supplier_id'] as String?,
      supplierName: map['supplier_name'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int) : null,
      items: map['items'] != null ? (map['items'] as List).map((e) => InvoiceItemModel.fromMap(e as Map<String, dynamic>)).toList() : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'customer_name': customerName,
      'invoice_number': invoiceNumber,
      'status': status,
      'invoice_date': invoiceDate.millisecondsSinceEpoch,
      'due_date': dueDate.millisecondsSinceEpoch,
      'subtotal': subtotal,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'balance_due': balanceDue,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'exchange_rate': exchangeRate,
      'notes': notes,
      'terms_and_conditions': termsAndConditions,
      'template_style': templateStyle,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_interval': recurringInterval,
      'recurring_next_date': recurringNextDate?.millisecondsSinceEpoch,
      'recurring_end_date': recurringEndDate?.millisecondsSinceEpoch,
      'is_purchase_order': isPurchaseOrder ? 1 : 0,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
    };
  }

  Invoice toEntity() {
    return Invoice(
      id: id,
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      status: status,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      subtotal: subtotal,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      paidAmount: paidAmount,
      balanceDue: balanceDue,
      currency: currency,
      currencySymbol: currencySymbol,
      exchangeRate: exchangeRate,
      notes: notes,
      termsAndConditions: termsAndConditions,
      templateStyle: templateStyle,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      recurringNextDate: recurringNextDate,
      recurringEndDate: recurringEndDate,
      isPurchaseOrder: isPurchaseOrder,
      supplierId: supplierId,
      supplierName: supplierName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      items: items.map((e) => e.toEntity()).toList(),
    );
  }

  factory InvoiceModel.fromEntity(Invoice entity) {
    return InvoiceModel(
      id: entity.id,
      businessId: entity.businessId,
      customerId: entity.customerId,
      customerName: entity.customerName,
      invoiceNumber: entity.invoiceNumber,
      status: entity.status,
      invoiceDate: entity.invoiceDate,
      dueDate: entity.dueDate,
      subtotal: entity.subtotal,
      discountPercent: entity.discountPercent,
      discountAmount: entity.discountAmount,
      taxPercent: entity.taxPercent,
      taxAmount: entity.taxAmount,
      grandTotal: entity.grandTotal,
      paidAmount: entity.paidAmount,
      balanceDue: entity.balanceDue,
      currency: entity.currency,
      currencySymbol: entity.currencySymbol,
      exchangeRate: entity.exchangeRate,
      notes: entity.notes,
      termsAndConditions: entity.termsAndConditions,
      templateStyle: entity.templateStyle,
      isRecurring: entity.isRecurring,
      recurringInterval: entity.recurringInterval,
      recurringNextDate: entity.recurringNextDate,
      recurringEndDate: entity.recurringEndDate,
      isPurchaseOrder: entity.isPurchaseOrder,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      items: entity.items.map((e) => InvoiceItemModel.fromEntity(e)).toList(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory InvoiceModel.fromJson(String source) => InvoiceModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class InvoiceItemModel {
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

  InvoiceItemModel({
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

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
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
      'invoice_id': invoiceId,
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

  InvoiceItem toEntity() {
    return InvoiceItem(
      id: id,
      invoiceId: invoiceId,
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

  factory InvoiceItemModel.fromEntity(InvoiceItem entity) {
    return InvoiceItemModel(
      id: entity.id,
      invoiceId: entity.invoiceId,
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
