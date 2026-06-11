class TaxRate {
  final String id;
  final String businessId;
  final String name;
  final String type;
  final double rate;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaxRate({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    required this.rate,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  TaxRate copyWith({
    String? id,
    String? businessId,
    String? name,
    String? type,
    double? rate,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaxRate(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      type: type ?? this.type,
      rate: rate ?? this.rate,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
