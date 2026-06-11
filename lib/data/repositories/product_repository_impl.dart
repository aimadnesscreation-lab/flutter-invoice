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
    final query = _db.select(_db.products)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull());

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final term = '%$searchQuery%';
      query.where((t) =>
        t.name.like(term) |
        t.sku.like(term) |
        t.barcode.like(term)
      );
    }

    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }

    query.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    query.limit(pageSize, offset: offset);

    final rows = await query.get();
    return rows.map((row) => ProductModel.fromMap(_rowToMap(row)).toEntity()).toList();
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

    await _logAudit(product.businessId, 'product', id, 'create', 'Created product ${product.name}');

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

    await _logAudit(product.businessId, 'product', product.id, 'update', 'Updated product ${product.name}');

    return updated.toEntity();
  }

  @override
  Future<void> deleteProduct(String id) async {
    final product = await getProductById(id);
    await (_db.products.update()
      ..where((t) => t.id.equals(id))).write(ProductsCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

    if (product != null) {
      await _logAudit(product.businessId, 'product', id, 'delete', 'Deleted product ${product.name}');
    }
  }

  @override
  Future<void> restoreProduct(String id) async {
    await (_db.products.update()
      ..where((t) => t.id.equals(id))).write(const ProductsCompanion(
        deletedAt: Value(null),
      ));
  }

  @override
  Future<int> getProductCount(String businessId) async {
    final countExp = _db.products.id.count();
    final query = _db.selectOnly(_db.products)
      ..addColumns([countExp])
      ..where(_db.products.businessId.equals(businessId))
      ..where(_db.products.deletedAt.isNull());
    
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<List<domain.Product>> getLowStockProducts(String businessId, {int limit = 20}) async {
    final query = _db.select(_db.products)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.quantity.isSmallerOrEqual(t.reorderLevel))
      ..where((t) => t.reorderLevel.isBiggerThanValue(0))
      ..limit(limit);
    
    final rows = await query.get();
    return rows.map((r) => ProductModel.fromMap(_rowToMap(r)).toEntity()).toList();
  }

  @override
  Future<double> getInventoryValuation(String businessId) async {
    final valuationExp = (_db.products.quantity * _db.products.costPrice).sum();
    final query = _db.selectOnly(_db.products)
      ..addColumns([valuationExp])
      ..where(_db.products.businessId.equals(businessId))
      ..where(_db.products.deletedAt.isNull());
    
    final row = await query.getSingle();
    return (row.read(valuationExp) as num?)?.toDouble() ?? 0.0;
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

  Future<void> _logAudit(String businessId, String entityType, String entityId, String action, String changes) async {
    await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
      id: const Uuid().v4(),
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      changes: changes,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}
