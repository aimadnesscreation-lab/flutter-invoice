import 'package:invoice_pro/domain/entities/product.dart';

class ProductModel {
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

  ProductModel({
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

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      categoryId: map['category_id'] as String?,
      categoryName: map['category_name'] as String?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (map['reorder_level'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'pcs',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'category_name': categoryName,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'reorder_level': reorderLevel,
      'unit': unit,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      businessId: businessId,
      categoryId: categoryId,
      categoryName: categoryName,
      sku: sku,
      barcode: barcode,
      name: name,
      description: description,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      quantity: quantity,
      reorderLevel: reorderLevel,
      unit: unit,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      businessId: entity.businessId,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      sku: entity.sku,
      barcode: entity.barcode,
      name: entity.name,
      description: entity.description,
      costPrice: entity.costPrice,
      sellingPrice: entity.sellingPrice,
      quantity: entity.quantity,
      reorderLevel: entity.reorderLevel,
      unit: entity.unit,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}
