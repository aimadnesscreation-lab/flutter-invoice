import 'package:invoice_pro/domain/entities/business.dart';

class BusinessModel {
  final String id;
  final String name;
  final String? logoPath;
  final String? address;
  final String? phone;
  final String? email;
  final String? taxNumber;
  final String currency;
  final String currencySymbol;
  final double defaultTaxRate;
  final String invoicePrefix;
  final String estimatePrefix;
  final String purchaseOrderPrefix;
  final String creditNotePrefix;
  final String expensePrefix;
  final String? notes;
  final String dateFormat;
  final String numberFormat;
  final String themeMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  BusinessModel({
    required this.id,
    required this.name,
    this.logoPath,
    this.address,
    this.phone,
    this.email,
    this.taxNumber,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.defaultTaxRate = 0.0,
    this.invoicePrefix = 'INV-',
    this.estimatePrefix = 'EST-',
    this.purchaseOrderPrefix = 'PO-',
    this.creditNotePrefix = 'CN-',
    this.expensePrefix = 'EXP-',
    this.notes,
    this.dateFormat = 'yyyy-MM-dd',
    this.numberFormat = 'en_US',
    this.themeMode = 'system',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      id: map['id'] as String,
      name: map['name'] as String,
      logoPath: map['logo_path'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      taxNumber: map['tax_number'] as String?,
      currency: map['currency'] as String? ?? 'USD',
      currencySymbol: map['currency_symbol'] as String? ?? '\$',
      defaultTaxRate: (map['default_tax_rate'] as num?)?.toDouble() ?? 0.0,
      invoicePrefix: map['invoice_prefix'] as String? ?? 'INV-',
      estimatePrefix: map['estimate_prefix'] as String? ?? 'EST-',
      purchaseOrderPrefix: map['purchase_order_prefix'] as String? ?? 'PO-',
      creditNotePrefix: map['credit_note_prefix'] as String? ?? 'CN-',
      expensePrefix: map['expense_prefix'] as String? ?? 'EXP-',
      notes: map['notes'] as String?,
      dateFormat: map['date_format'] as String? ?? 'yyyy-MM-dd',
      numberFormat: map['number_format'] as String? ?? 'en_US',
      themeMode: map['theme_mode'] as String? ?? 'system',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logo_path': logoPath,
      'address': address,
      'phone': phone,
      'email': email,
      'tax_number': taxNumber,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'default_tax_rate': defaultTaxRate,
      'invoice_prefix': invoicePrefix,
      'estimate_prefix': estimatePrefix,
      'purchase_order_prefix': purchaseOrderPrefix,
      'credit_note_prefix': creditNotePrefix,
      'expense_prefix': expensePrefix,
      'notes': notes,
      'date_format': dateFormat,
      'number_format': numberFormat,
      'theme_mode': themeMode,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
    };
  }

  Business toEntity() {
    return Business(
      id: id,
      name: name,
      logoPath: logoPath,
      address: address,
      phone: phone,
      email: email,
      taxNumber: taxNumber,
      currency: currency,
      currencySymbol: currencySymbol,
      defaultTaxRate: defaultTaxRate,
      invoicePrefix: invoicePrefix,
      estimatePrefix: estimatePrefix,
      purchaseOrderPrefix: purchaseOrderPrefix,
      creditNotePrefix: creditNotePrefix,
      expensePrefix: expensePrefix,
      notes: notes,
      dateFormat: dateFormat,
      numberFormat: numberFormat,
      themeMode: themeMode,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  factory BusinessModel.fromEntity(Business entity) {
    return BusinessModel(
      id: entity.id,
      name: entity.name,
      logoPath: entity.logoPath,
      address: entity.address,
      phone: entity.phone,
      email: entity.email,
      taxNumber: entity.taxNumber,
      currency: entity.currency,
      currencySymbol: entity.currencySymbol,
      defaultTaxRate: entity.defaultTaxRate,
      invoicePrefix: entity.invoicePrefix,
      estimatePrefix: entity.estimatePrefix,
      purchaseOrderPrefix: entity.purchaseOrderPrefix,
      creditNotePrefix: entity.creditNotePrefix,
      expensePrefix: entity.expensePrefix,
      notes: entity.notes,
      dateFormat: entity.dateFormat,
      numberFormat: entity.numberFormat,
      themeMode: entity.themeMode,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}
