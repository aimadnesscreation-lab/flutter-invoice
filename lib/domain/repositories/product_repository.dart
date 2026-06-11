import 'package:invoice_pro/domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAllProducts(String businessId, {String? searchQuery, String? categoryId, int page = 1, int pageSize = 20});
  Future<Product?> getProductById(String id);
  Future<Product?> getProductByBarcode(String barcode, String businessId);
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<void> restoreProduct(String id);
  Future<int> getProductCount(String businessId);
  Future<List<Product>> getLowStockProducts(String businessId, {int limit = 20});
  Future<double> getInventoryValuation(String businessId);
}
