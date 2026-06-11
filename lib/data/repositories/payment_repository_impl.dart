import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/payment_model.dart';
import 'package:invoice_pro/domain/entities/payment.dart' as domain;
import 'package:invoice_pro/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final AppDatabase _db;

  PaymentRepositoryImpl(this._db);

  @override
  Future<List<domain.Payment>> getAllPayments(String businessId, {String? invoiceId, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    var allRows = await (_db.payments.select()
      ..where((t) => t.businessId.equals(businessId))).get();
    var rows = allRows;

    if (invoiceId != null) {
      rows = rows.where((r) => r.invoiceId == invoiceId).toList();
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paged = rows.skip(offset).take(pageSize).toList();

    final result = <domain.Payment>[];
    for (final r in paged) {
      result.add(await _toEntity(r));
    }
    return result;
  }

  @override
  Future<domain.Payment?> getPaymentById(String id) async {
    final row = await (_db.payments.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<domain.Payment> createPayment(domain.Payment payment) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final model = PaymentModel(
      id: id,
      businessId: payment.businessId,
      invoiceId: payment.invoiceId,
      invoiceNumber: payment.invoiceNumber,
      customerId: payment.customerId,
      customerName: payment.customerName,
      paymentNumber: payment.paymentNumber,
      amount: payment.amount,
      method: payment.method,
      reference: payment.reference,
      notes: payment.notes,
      isRefund: payment.isRefund,
      paymentDate: payment.paymentDate,
      createdAt: now,
    );
    await _db.into(_db.payments).insert(PaymentsCompanion.insert(
      id: model.id,
      businessId: model.businessId,
      invoiceId: Value(model.invoiceId),
      customerId: Value(model.customerId),
      paymentNumber: model.paymentNumber,
      amount: model.amount,
      method: model.method,
      reference: Value(model.reference),
      notes: Value(model.notes),
      isRefund: Value(model.isRefund),
      paymentDate: model.paymentDate.millisecondsSinceEpoch,
      createdAt: model.createdAt.millisecondsSinceEpoch,
    ));

    // Update invoice paid amount
    if (payment.invoiceId != null && !payment.isRefund) {
      final invoiceRow = await (_db.invoices.select()
        ..where((t) => t.id.equals(payment.invoiceId!))).getSingleOrNull();
      if (invoiceRow != null) {
        final newPaid = invoiceRow.paidAmount + payment.amount;
        final newBalance = invoiceRow.grandTotal - newPaid;
        final newStatus = newBalance <= 0 ? 'paid' : (newPaid > 0 ? 'partial' : invoiceRow.status);
        await (_db.invoices.update()
          ..where((t) => t.id.equals(payment.invoiceId!))).write(InvoicesCompanion(
            paidAmount: Value(newPaid),
            balanceDue: Value(newBalance > 0 ? newBalance : 0),
            status: Value(newStatus),
          ));
      }
    }

    return model.toEntity();
  }

  @override
  Future<void> deletePayment(String id) async {
    await (_db.payments.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<double> getTotalPayments(String businessId) async {
    final rows = await (_db.payments.select()
      ..where((t) => t.businessId.equals(businessId))).get();
    return rows
        .where((r) => !r.isRefund)
        .fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  @override
  Future<double> getInvoicePaidAmount(String invoiceId) async {
    final rows = await (_db.payments.select()
      ..where((t) => t.invoiceId.equals(invoiceId))).get();
    return rows
        .where((r) => !r.isRefund)
        .fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  @override
  Future<List<domain.Payment>> getPaymentsByInvoiceId(String invoiceId) async {
    final rows = await (_db.payments.select()
      ..where((t) => t.invoiceId.equals(invoiceId))).get();
    final result = <domain.Payment>[];
    for (final r in rows) {
      result.add(await _toEntity(r));
    }
    return result;
  }

  Future<domain.Payment> _toEntity(Payment row) async {
    final map = _rowToMap(row);
    // Populate denormalized fields from related tables
    if (row.invoiceId != null) {
      final invoice = await (_db.invoices.select()
        ..where((t) => t.id.equals(row.invoiceId!))).getSingleOrNull();
      if (invoice != null) {
        map['invoice_number'] = invoice.invoiceNumber;
        // Also try to get customer name from the invoice's customer
        if (invoice.customerId != null) {
          final customer = await (_db.customers.select()
            ..where((t) => t.id.equals(invoice.customerId!))).getSingleOrNull();
          if (customer != null) {
            map['customer_name'] = customer.name;
          }
        }
      }
    }
    return PaymentModel.fromMap(map).toEntity();
  }

  Map<String, dynamic> _rowToMap(Payment row) {
    return {
      'id': row.id,
      'business_id': row.businessId,
      'invoice_id': row.invoiceId,
      'invoice_number': null, // Payments table doesn't have invoice_number column
      'customer_id': row.customerId,
      'customer_name': null, // Payments table doesn't have customer_name column
      'payment_number': row.paymentNumber,
      'amount': row.amount,
      'method': row.method,
      'reference': row.reference,
      'notes': row.notes,
      'is_refund': row.isRefund ? 1 : 0,
      'payment_date': row.paymentDate,
      'created_at': row.createdAt,
    };
  }
}
