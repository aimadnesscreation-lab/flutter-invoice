import 'package:invoice_pro/domain/entities/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getAllCustomers(String businessId, {String? searchQuery, int page = 1, int pageSize = 20});
  Future<Customer?> getCustomerById(String id);
  Future<Customer> createCustomer(Customer customer);
  Future<Customer> updateCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
  Future<void> restoreCustomer(String id);
  Future<int> getCustomerCount(String businessId);
  Future<Map<String, dynamic>> getCustomerStats(String businessId);
  Future<List<Customer>> getTopCustomers(String businessId, {int limit = 10});
  Future<List<Customer>> getOutstandingCustomers(String businessId, {int limit = 10});
}
