import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/product_model.dart';
import 'package:invoice_pro/domain/entities/product.dart' as domain;
import 'package:invoice_pro/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final AppDatabase _db;

  ProductRepositoryImpl(this._db);

  @override
  Future<List<domain.Product>> getAllProducts(String businessId, {String? searchQuery, String? categoryId, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    var allRows = await (_db.products.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    var rows = allRows;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      rows = rows.where((r) =>
        r.name.toLowerCase().contains(query) ||
        (r.sku?.toLowerCase().contains(query) ?? false) ||
        (r.barcode?.contains(query) ?? false)
      ).toList();
    }

    if (categoryId != null) {
      rows = rows.where((r) => r.categoryId == categoryId).toList();
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paged = rows.skip(offset).take(pageSize).toList();

    return paged.map((row) => ProductModel.fromMap(_rowToMap(row)).toEntity()).toList();
  }

  @override
  Future<domain.Product?> getProductById(String id) async {
    final row = await (_db.products.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return ProductModel.fromMap(_rowToMap(row)).toEntity();
  }

  @override
  Future<domain.Product?> getProductByBarcode(String barcode, String businessId) async {
    final rows = await (_db.products.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.barcode.equals(barcode))).get();
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(_rowToMap(rows.first)).toEntity();
  }

  @override
  Future<domain.Product> createProduct(domain.Product product) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final model = ProductModel(
      id: id,
      businessId: product.businessId,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      sku: product.sku,
      barcode: product.barcode,
      name: product.name,
      description: product.description,
      costPrice: product.costPrice,
      sellingPrice: product.sellingPrice,
      quantity: product.quantity,
      reorderLevel: product.reorderLevel,
      unit: product.unit,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.products).insert(ProductsCompanion.insert(
      id: model.id,
      businessId: model.businessId,
      categoryId: Value(model.categoryId),
      sku: Value(model.sku),
      barcode: Value(model.barcode),
      name: model.name,
      description: Value(model.description),
      costPrice: Value(model.costPrice),
      sellingPrice: Value(model.sellingPrice),
      quantity: Value(model.quantity),
      reorderLevel: Value(model.reorderLevel),
      unit: Value(model.unit),
      createdAt: model.createdAt.millisecondsSinceEpoch,
      updatedAt: model.updatedAt.millisecondsSinceEpoch,
    ));
    return model.toEntity();
  }

  @override
  Future<domain.Product> updateProduct(domain.Product product) async {
    final model = ProductModel.fromEntity(product);
    final updated = ProductModel(
      id: model.id,
      businessId: model.businessId,
      categoryId: model.categoryId,
      categoryName: model.categoryName,
      sku: model.sku,
      barcode: model.barcode,
      name: model.name,
      description: model.description,
      costPrice: model.costPrice,
      sellingPrice: model.sellingPrice,
      quantity: model.quantity,
      reorderLevel: model.reorderLevel,
      unit: model.unit,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: model.deletedAt,
    );
    await (_db.products.update()
      ..where((t) => t.id.equals(updated.id))).write(ProductsCompanion(
        categoryId: Value(updated.categoryId),
        sku: Value(updated.sku),
        barcode: Value(updated.barcode),
        name: Value(updated.name),
        description: Value(updated.description),
        costPrice: Value(updated.costPrice),
        sellingPrice: Value(updated.sellingPrice),
        quantity: Value(updated.quantity),
        reorderLevel: Value(updated.reorderLevel),
        unit: Value(updated.unit),
        updatedAt: Value(updated.updatedAt.millisecondsSinceEpoch),
        deletedAt: Value(updated.deletedAt?.millisecondsSinceEpoch),
      ));
    return updated.toEntity();
  }

  @override
  Future<void> deleteProduct(String id) async {
    await (_db.products.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> restoreProduct(String id) async {}

  @override
  Future<int> getProductCount(String businessId) async {
    final rows = await (_db.products.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    return rows.length;
  }

  @override
  Future<List<domain.Product>> getLowStockProducts(String businessId, {int limit = 20}) async {
    final allRows = await (_db.products.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    final rows = allRows
        .where((r) => r.quantity <= r.reorderLevel && r.reorderLevel > 0)
        .take(limit)
        .toList();
    return rows.map((r) => ProductModel.fromMap(_rowToMap(r)).toEntity()).toList();
  }

  @override
  Future<double> getInventoryValuation(String businessId) async {
    final rows = await (_db.products.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    double total = 0;
    for (final r in rows) {
      total += r.quantity * r.costPrice;
    }
    return total;
  }

  Map<String, dynamic> _rowToMap(Product row) {
    return {
      'id': row.id,
      'business_id': row.businessId,
      'category_id': row.categoryId,
      'sku': row.sku,
      'barcode': row.barcode,
      'name': row.name,
      'description': row.description,
      'cost_price': row.costPrice,
      'selling_price': row.sellingPrice,
      'quantity': row.quantity,
      'reorder_level': row.reorderLevel,
      'unit': row.unit,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'deleted_at': row.deletedAt,
    };
  }
}
