class CreditNote {
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

  CreditNote({
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

  CreditNote copyWith({
    String? id,
    String? businessId,
    String? invoiceId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? creditNoteNumber,
    String? reason,
    double? amount,
    DateTime? creditNoteDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditNote(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      creditNoteNumber: creditNoteNumber ?? this.creditNoteNumber,
      reason: reason ?? this.reason,
      amount: amount ?? this.amount,
      creditNoteDate: creditNoteDate ?? this.creditNoteDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
