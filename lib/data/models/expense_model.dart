import 'package:invoice_pro/domain/entities/expense.dart';

class ExpenseModel {
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

  ExpenseModel({
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

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      expenseNumber: map['expense_number'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      expenseDate: DateTime.fromMillisecondsSinceEpoch(map['expense_date'] as int),
      notes: map['notes'] as String?,
      receiptPath: map['receipt_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'expense_number': expenseNumber,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.millisecondsSinceEpoch,
      'notes': notes,
      'receipt_path': receiptPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
    };
  }

  Expense toEntity() {
    return Expense(
      id: id,
      businessId: businessId,
      expenseNumber: expenseNumber,
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      notes: notes,
      receiptPath: receiptPath,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      businessId: entity.businessId,
      expenseNumber: entity.expenseNumber,
      category: entity.category,
      amount: entity.amount,
      expenseDate: entity.expenseDate,
      notes: entity.notes,
      receiptPath: entity.receiptPath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}
