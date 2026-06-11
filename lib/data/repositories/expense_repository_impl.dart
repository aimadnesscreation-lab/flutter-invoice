import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/expense_model.dart';
import 'package:invoice_pro/domain/entities/expense.dart' as domain;
import 'package:invoice_pro/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;
  final Map<String, int> _counters = {};

  ExpenseRepositoryImpl(this._db);

  @override
  Future<List<domain.Expense>> getAllExpenses(String businessId, {String? category, String? searchQuery, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    var allRows = await (_db.expenses.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    var rows = allRows;

    if (category != null) {
      rows = rows.where((r) => r.category == category).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      rows = rows.where((r) =>
        r.expenseNumber.toLowerCase().contains(query) ||
        r.category.toLowerCase().contains(query) ||
        (r.notes?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paged = rows.skip(offset).take(pageSize).toList();

    return paged.map((r) => ExpenseModel.fromMap(_rowToMap(r)).toEntity()).toList();
  }

  @override
  Future<domain.Expense?> getExpenseById(String id) async {
    final row = await (_db.expenses.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return ExpenseModel.fromMap(_rowToMap(row)).toEntity();
  }

  @override
  Future<domain.Expense> createExpense(domain.Expense expense) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final model = ExpenseModel(
      id: id,
      businessId: expense.businessId,
      expenseNumber: expense.expenseNumber,
      category: expense.category,
      amount: expense.amount,
      expenseDate: expense.expenseDate,
      notes: expense.notes,
      receiptPath: expense.receiptPath,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
      id: model.id,
      businessId: model.businessId,
      expenseNumber: model.expenseNumber,
      category: model.category,
      amount: model.amount,
      expenseDate: model.expenseDate.millisecondsSinceEpoch,
      notes: Value(model.notes),
      receiptPath: Value(model.receiptPath),
      createdAt: model.createdAt.millisecondsSinceEpoch,
      updatedAt: model.updatedAt.millisecondsSinceEpoch,
    ));
    return model.toEntity();
  }

  @override
  Future<domain.Expense> updateExpense(domain.Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    final updated = ExpenseModel(
      id: model.id,
      businessId: model.businessId,
      expenseNumber: model.expenseNumber,
      category: model.category,
      amount: model.amount,
      expenseDate: model.expenseDate,
      notes: model.notes,
      receiptPath: model.receiptPath,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
    );
    await (_db.expenses.update()
      ..where((t) => t.id.equals(updated.id))).write(ExpensesCompanion(
        expenseNumber: Value(updated.expenseNumber),
        category: Value(updated.category),
        amount: Value(updated.amount),
        expenseDate: Value(updated.expenseDate.millisecondsSinceEpoch),
        notes: Value(updated.notes),
        receiptPath: Value(updated.receiptPath),
        updatedAt: Value(updated.updatedAt.millisecondsSinceEpoch),
      ));
    return updated.toEntity();
  }

  @override
  Future<void> deleteExpense(String id) async {
    await (_db.expenses.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> restoreExpense(String id) async {}

  @override
  Future<double> getTotalExpenses(String businessId) async {
    final rows = await (_db.expenses.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  @override
  Future<double> getMonthlyExpenses(String businessId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final rows = await (_db.expenses.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    return rows
        .where((r) => r.expenseDate >= startOfMonth)
        .fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  @override
  Future<double> getYearlyExpenses(String businessId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
    final rows = await (_db.expenses.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    return rows
        .where((r) => r.expenseDate >= startOfYear)
        .fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  @override
  Future<Map<String, double>> getExpenseByCategory(String businessId) async {
    final rows = await (_db.expenses.select()
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull())).get();
    final Map<String, double> result = {};
    for (final r in rows) {
      result[r.category] = (result[r.category] ?? 0) + r.amount;
    }
    return result;
  }

  @override
  Future<String> generateExpenseNumber(String businessId, String prefix) async {
    _counters[businessId] = (_counters[businessId] ?? 0) + 1;
    return '$prefix${_counters[businessId]!.toString().padLeft(6, '0')}';
  }

  Map<String, dynamic> _rowToMap(Expense row) {
    return {
      'id': row.id,
      'business_id': row.businessId,
      'expense_number': row.expenseNumber,
      'category': row.category,
      'amount': row.amount,
      'expense_date': row.expenseDate,
      'notes': row.notes,
      'receipt_path': row.receiptPath,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'deleted_at': row.deletedAt,
    };
  }
}
