import 'package:invoice_pro/domain/entities/payment.dart';

abstract class PaymentRepository {
  Future<List<Payment>> getAllPayments(String businessId, {String? invoiceId, int page = 1, int pageSize = 20});
  Future<Payment?> getPaymentById(String id);
  Future<Payment> createPayment(Payment payment);
  Future<void> deletePayment(String id);
  Future<double> getTotalPayments(String businessId);
  Future<double> getInvoicePaidAmount(String invoiceId);
  Future<List<Payment>> getPaymentsByInvoiceId(String invoiceId);
}
