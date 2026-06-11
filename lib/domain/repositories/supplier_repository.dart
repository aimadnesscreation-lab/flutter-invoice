import 'package:invoice_pro/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getAllSuppliers(String businessId, {String? searchQuery, int page = 1, int pageSize = 20});
  Future<Supplier?> getSupplierById(String id);
  Future<Supplier> createSupplier(Supplier supplier);
  Future<Supplier> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
}
