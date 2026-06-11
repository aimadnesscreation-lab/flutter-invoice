import 'package:invoice_pro/domain/entities/business.dart';

abstract class BusinessRepository {
  Future<List<Business>> getAllBusinesses();
  Future<Business?> getBusinessById(String id);
  Future<Business> createBusiness(Business business);
  Future<Business> updateBusiness(Business business);
  Future<void> deleteBusiness(String id);
  Future<void> restoreBusiness(String id);
  Future<Business?> getActiveBusiness();
  Future<void> setActiveBusiness(String id);
}
