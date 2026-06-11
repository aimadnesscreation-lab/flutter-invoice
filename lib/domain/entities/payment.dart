class Payment {
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

  Payment({
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

  Payment copyWith({
    String? id,
    String? businessId,
    String? invoiceId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? paymentNumber,
    double? amount,
    String? method,
    String? reference,
    String? notes,
    bool? isRefund,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      isRefund: isRefund ?? this.isRefund,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
