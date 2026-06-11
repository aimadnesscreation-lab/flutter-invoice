class Customer {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final int totalInvoices;
  final double totalPurchases;
  final double outstandingBalance;
  final DateTime? lastInvoiceDate;

  Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.totalInvoices = 0,
    this.totalPurchases = 0.0,
    this.outstandingBalance = 0.0,
    this.lastInvoiceDate,
  });

  Customer copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? taxNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? totalInvoices,
    double? totalPurchases,
    double? outstandingBalance,
    DateTime? lastInvoiceDate,
  }) {
    return Customer(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
    );
  }
}
