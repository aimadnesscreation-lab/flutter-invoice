import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/expense_model.dart';
import 'package:invoice_pro/domain/entities/expense.dart' as domain;
import 'package:invoice_pro/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepositoryImpl(this._db);

  @override
  Future<List<domain.Expense>> getAllExpenses(String businessId, {String? category, String? searchQuery, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    final query = _db.select(_db.expenses)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.deletedAt.isNull());

    if (category != null && category.isNotEmpty) {
      query.where((t) => t.category.equals(category));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final term = '%$searchQuery%';
      query.where((t) =>
        t.expenseNumber.like(term) |
        t.category.like(term) |
        t.notes.like(term)
      );
    }

    query.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    query.limit(pageSize, offset: offset);

    final rows = await query.get();
    return rows.map((r) => ExpenseModel.fromMap(_rowToMap(r)).toEntity()).toList();
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
      deletedAt: model.deletedAt,
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
        deletedAt: Value(updated.deletedAt?.millisecondsSinceEpoch),
      ));
    return updated.toEntity();
  }

  @override
  Future<void> deleteExpense(String id) async {
    await (_db.expenses.update()
      ..where((t) => t.id.equals(id))).write(ExpensesCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
  }

  @override
  Future<void> restoreExpense(String id) async {
    await (_db.expenses.update()
      ..where((t) => t.id.equals(id))).write(const ExpensesCompanion(
        deletedAt: Value(null),
      ));
  }

  @override
  Future<double> getTotalExpenses(String businessId) async {
    final amountExp = _db.expenses.amount.sum();
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([amountExp])
      ..where(_db.expenses.businessId.equals(businessId))
      ..where(_db.expenses.deletedAt.isNull());
    
    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  @override
  Future<double> getMonthlyExpenses(String businessId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    
    final amountExp = _db.expenses.amount.sum();
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([amountExp])
      ..where(_db.expenses.businessId.equals(businessId))
      ..where(_db.expenses.deletedAt.isNull())
      ..where(_db.expenses.expenseDate.isBiggerOrEqualValue(startOfMonth));
    
    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  @override
  Future<double> getYearlyExpenses(String businessId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
    
    final amountExp = _db.expenses.amount.sum();
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([amountExp])
      ..where(_db.expenses.businessId.equals(businessId))
      ..where(_db.expenses.deletedAt.isNull())
      ..where(_db.expenses.expenseDate.isBiggerOrEqualValue(startOfYear));
    
    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  @override
  Future<Map<String, double>> getExpenseByCategory(String businessId) async {
    final amountExp = _db.expenses.amount.sum();
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.category, amountExp])
      ..where(_db.expenses.businessId.equals(businessId))
      ..where(_db.expenses.deletedAt.isNull())
      ..groupBy([_db.expenses.category]);
    
    final rows = await query.get();
    return {for (final r in rows) r.read(_db.expenses.category)!: r.read(amountExp)!};
  }

  @override
  Future<String> generateExpenseNumber(String businessId, String prefix) async {
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.id.count()])
      ..where(_db.expenses.businessId.equals(businessId));
    final count = await query.map((row) => row.read(_db.expenses.id.count())).getSingle();
    final nextNumber = (count ?? 0) + 1;
    return '$prefix${nextNumber.toString().padLeft(6, '0')}';
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
