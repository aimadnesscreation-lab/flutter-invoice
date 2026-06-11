import 'package:invoice_pro/domain/entities/credit_note.dart';

class CreditNoteModel {
  final String id;
  final String businessId;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? customerId;
  final String? customerName;
  final String creditNoteNumber;
  final String reason;
  final double amount;
  final DateTime creditNoteDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditNoteModel({
    required this.id,
    required this.businessId,
    this.invoiceId,
    this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.creditNoteNumber,
    required this.reason,
    required this.amount,
    required this.creditNoteDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CreditNoteModel.fromMap(Map<String, dynamic> map) {
    return CreditNoteModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      invoiceId: map['invoice_id'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      creditNoteNumber: map['credit_note_number'] as String,
      reason: map['reason'] as String,
      amount: (map['amount'] as num).toDouble(),
      creditNoteDate: DateTime.fromMillisecondsSinceEpoch(map['credit_note_date'] as int),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
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
      'credit_note_number': creditNoteNumber,
      'reason': reason,
      'amount': amount,
      'credit_note_date': creditNoteDate.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  CreditNote toEntity() {
    return CreditNote(
      id: id,
      businessId: businessId,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      creditNoteNumber: creditNoteNumber,
      reason: reason,
      amount: amount,
      creditNoteDate: creditNoteDate,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CreditNoteModel.fromEntity(CreditNote entity) {
    return CreditNoteModel(
      id: entity.id,
      businessId: entity.businessId,
      invoiceId: entity.invoiceId,
      invoiceNumber: entity.invoiceNumber,
      customerId: entity.customerId,
      customerName: entity.customerName,
      creditNoteNumber: entity.creditNoteNumber,
      reason: entity.reason,
      amount: entity.amount,
      creditNoteDate: entity.creditNoteDate,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
