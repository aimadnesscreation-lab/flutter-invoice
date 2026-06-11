class Product {
  final String id;
  final String businessId;
  final String? categoryId;
  final String? categoryName;
  final String? sku;
  final String? barcode;
  final String name;
  final String? description;
  final double costPrice;
  final double sellingPrice;
  final double quantity;
  final double reorderLevel;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Product({
    required this.id,
    required this.businessId,
    this.categoryId,
    this.categoryName,
    this.sku,
    this.barcode,
    required this.name,
    this.description,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    this.quantity = 0.0,
    this.reorderLevel = 0.0,
    this.unit = 'pcs',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isLowStock => quantity <= reorderLevel && reorderLevel > 0;
  double get inventoryValue => quantity * costPrice;

  Product copyWith({
    String? id,
    String? businessId,
    String? categoryId,
    String? categoryName,
    String? sku,
    String? barcode,
    String? name,
    String? description,
    double? costPrice,
    double? sellingPrice,
    double? quantity,
    double? reorderLevel,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
