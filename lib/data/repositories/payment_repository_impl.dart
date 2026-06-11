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
    final query = _db.select(_db.payments).join([
      leftOuterJoin(_db.invoices, _db.invoices.id.equalsExp(_db.payments.invoiceId)),
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.payments.customerId)),
    ])
      ..where(_db.payments.businessId.equals(businessId));

    if (invoiceId != null) {
      query.where(_db.payments.invoiceId.equals(invoiceId));
    }

    query.orderBy([OrderingTerm(expression: _db.payments.createdAt, mode: OrderingMode.desc)]);
    query.limit(pageSize, offset: offset);

    final rows = await query.get();
    return rows.map((row) {
      final payment = row.readTable(_db.payments);
      final invoice = row.readTableOrNull(_db.invoices);
      final customer = row.readTableOrNull(_db.customers);
      
      final map = _rowToMap(payment);
      if (invoice != null) {
        map['invoice_number'] = invoice.invoiceNumber;
      }
      if (customer != null) {
        map['customer_name'] = customer.name;
      }
      return PaymentModel.fromMap(map).toEntity();
    }).toList();
  }

  @override
  Future<domain.Payment?> getPaymentById(String id) async {
    final query = _db.select(_db.payments).join([
      leftOuterJoin(_db.invoices, _db.invoices.id.equalsExp(_db.payments.invoiceId)),
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.payments.customerId)),
    ])
      ..where(_db.payments.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final payment = row.readTable(_db.payments);
    final invoice = row.readTableOrNull(_db.invoices);
    final customer = row.readTableOrNull(_db.customers);
    
    final map = _rowToMap(payment);
    if (invoice != null) {
      map['invoice_number'] = invoice.invoiceNumber;
    }
    if (customer != null) {
      map['customer_name'] = customer.name;
    }
    return PaymentModel.fromMap(map).toEntity();
  }

  @override
  Future<domain.Payment> createPayment(domain.Payment payment) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    
    return await _db.transaction(() async {
      await _db.into(_db.payments).insert(PaymentsCompanion.insert(
        id: id,
        businessId: payment.businessId,
        invoiceId: Value(payment.invoiceId),
        customerId: Value(payment.customerId),
        paymentNumber: payment.paymentNumber,
        amount: payment.amount,
        method: payment.method,
        reference: Value(payment.reference),
        notes: Value(payment.notes),
        isRefund: Value(payment.isRefund),
        paymentDate: payment.paymentDate.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
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

      await _logAudit(payment.businessId, 'payment', id, 'create',
          '${payment.isRefund ? "Refund" : "Payment"} ${payment.paymentNumber}: ${payment.amount} via ${payment.method}');

      final created = await getPaymentById(id);
      return created!;
    });
  }

  @override
  Future<String> generatePaymentNumber(String businessId, String prefix) async {
    return await _db.transaction(() async {
      final query = _db.select(_db.invoiceNumbering)
        ..where((t) => t.businessId.equals(businessId))
        ..where((t) => t.type.equals('payment'))
        ..where((t) => t.prefix.equals(prefix));
      
      final existing = await query.getSingleOrNull();
      int nextNumber = 1;

      if (existing != null) {
        nextNumber = existing.lastNumber + 1;
        await (_db.invoiceNumbering.update()..where((t) => t.id.equals(existing.id))).write(
          InvoiceNumberingCompanion(lastNumber: Value(nextNumber))
        );
      } else {
        await _db.into(_db.invoiceNumbering).insert(InvoiceNumberingCompanion.insert(
          id: const Uuid().v4(),
          businessId: businessId,
          prefix: prefix,
          type: 'payment',
          lastNumber: Value(nextNumber),
        ));
      }

      return '$prefix${nextNumber.toString().padLeft(6, '0')}';
    });
  }

  @override
  Future<void> deletePayment(String id) async {
    final payment = await getPaymentById(id);
    await (_db.payments.delete()
      ..where((t) => t.id.equals(id))).go();
    if (payment != null) {
      await _logAudit(payment.businessId, 'payment', id, 'delete', 'Deleted payment ${payment.paymentNumber}');
    }
  }

  @override
  Future<double> getTotalPayments(String businessId) async {
    final amountExp = _db.payments.amount.sum();
    final query = _db.selectOnly(_db.payments)
      ..addColumns([amountExp])
      ..where(_db.payments.businessId.equals(businessId))
      ..where(_db.payments.isRefund.equals(false));
    
    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  @override
  Future<double> getInvoicePaidAmount(String invoiceId) async {
    final amountExp = _db.payments.amount.sum();
    final query = _db.selectOnly(_db.payments)
      ..addColumns([amountExp])
      ..where(_db.payments.invoiceId.equals(invoiceId))
      ..where(_db.payments.isRefund.equals(false));
    
    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  @override
  Future<List<domain.Payment>> getPaymentsByInvoiceId(String invoiceId) async {
    final query = _db.select(_db.payments).join([
      leftOuterJoin(_db.invoices, _db.invoices.id.equalsExp(_db.payments.invoiceId)),
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.payments.customerId)),
    ])
      ..where(_db.payments.invoiceId.equals(invoiceId));

    final rows = await query.get();
    return rows.map((row) {
      final payment = row.readTable(_db.payments);
      final invoice = row.readTableOrNull(_db.invoices);
      final customer = row.readTableOrNull(_db.customers);
      
      final map = _rowToMap(payment);
      if (invoice != null) {
        map['invoice_number'] = invoice.invoiceNumber;
      }
      if (customer != null) {
        map['customer_name'] = customer.name;
      }
      return PaymentModel.fromMap(map).toEntity();
    }).toList();
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
