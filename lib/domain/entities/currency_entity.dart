class CurrencyEntity {
  final String id;
  final String businessId;
  final String code;
  final String name;
  final String symbol;
  final double exchangeRate;
  final bool isDefault;
  final DateTime createdAt;

  CurrencyEntity({
    required this.id,
    required this.businessId,
    required this.code,
    required this.name,
    required this.symbol,
    this.exchangeRate = 1.0,
    this.isDefault = false,
    required this.createdAt,
  });

  CurrencyEntity copyWith({
    String? id,
    String? businessId,
    String? code,
    String? name,
    String? symbol,
    double? exchangeRate,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CurrencyEntity(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
