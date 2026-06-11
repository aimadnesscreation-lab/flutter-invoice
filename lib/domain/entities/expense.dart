class Expense {
  final String id;
  final String businessId;
  final String expenseNumber;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String? notes;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  static const List<String> categories = [
    'Rent',
    'Utilities',
    'Salaries',
    'Fuel',
    'Office',
    'Marketing',
    'Miscellaneous',
  ];

  Expense({
    required this.id,
    required this.businessId,
    required this.expenseNumber,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.notes,
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Expense copyWith({
    String? id,
    String? businessId,
    String? expenseNumber,
    String? category,
    double? amount,
    DateTime? expenseDate,
    String? notes,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
