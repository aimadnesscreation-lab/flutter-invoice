import 'package:invoice_pro/domain/entities/payment.dart';

class PaymentModel {
  final String id;
  final String businessId;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? customerId;
  final String? customerName;
  final String paymentNumber;
  final double amount;
  final String method;
  final String? reference;
  final String? notes;
  final bool isRefund;
  final DateTime paymentDate;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.businessId,
    this.invoiceId,
    this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.paymentNumber,
    required this.amount,
    required this.method,
    this.reference,
    this.notes,
    this.isRefund = false,
    required this.paymentDate,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      invoiceId: map['invoice_id'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      paymentNumber: map['payment_number'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: map['method'] as String,
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      isRefund: map['is_refund'] == 1 || map['is_refund'] == true,
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['payment_date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'invoice_id': invoiceId,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'payment_number': paymentNumber,
      'amount': amount,
      'method': method,
      'reference': reference,
      'notes': notes,
      'is_refund': isRefund ? 1 : 0,
      'payment_date': paymentDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Payment toEntity() {
    return Payment(
      id: id,
      businessId: businessId,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      paymentNumber: paymentNumber,
      amount: amount,
      method: method,
      reference: reference,
      notes: notes,
      isRefund: isRefund,
      paymentDate: paymentDate,
      createdAt: createdAt,
    );
  }

  factory PaymentModel.fromEntity(Payment entity) {
    return PaymentModel(
      id: entity.id,
      businessId: entity.businessId,
      invoiceId: entity.invoiceId,
      invoiceNumber: entity.invoiceNumber,
      customerId: entity.customerId,
      customerName: entity.customerName,
      paymentNumber: entity.paymentNumber,
      amount: entity.amount,
      method: entity.method,
      reference: entity.reference,
      notes: entity.notes,
      isRefund: entity.isRefund,
      paymentDate: entity.paymentDate,
      createdAt: entity.createdAt,
    );
  }
}
