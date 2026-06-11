class Business {
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

  Business({
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

  Business copyWith({
    String? id,
    String? name,
    String? logoPath,
    String? address,
    String? phone,
    String? email,
    String? taxNumber,
    String? currency,
    String? currencySymbol,
    double? defaultTaxRate,
    String? invoicePrefix,
    String? estimatePrefix,
    String? purchaseOrderPrefix,
    String? creditNotePrefix,
    String? expensePrefix,
    String? notes,
    String? dateFormat,
    String? numberFormat,
    String? themeMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxNumber: taxNumber ?? this.taxNumber,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      estimatePrefix: estimatePrefix ?? this.estimatePrefix,
      purchaseOrderPrefix: purchaseOrderPrefix ?? this.purchaseOrderPrefix,
      creditNotePrefix: creditNotePrefix ?? this.creditNotePrefix,
      expensePrefix: expensePrefix ?? this.expensePrefix,
      notes: notes ?? this.notes,
      dateFormat: dateFormat ?? this.dateFormat,
      numberFormat: numberFormat ?? this.numberFormat,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
