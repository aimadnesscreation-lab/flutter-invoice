import 'package:invoice_pro/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getAllExpenses(String businessId, {String? category, String? searchQuery, int page = 1, int pageSize = 20});
  Future<Expense?> getExpenseById(String id);
  Future<Expense> createExpense(Expense expense);
  Future<Expense> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<void> restoreExpense(String id);
  Future<double> getTotalExpenses(String businessId);
  Future<double> getMonthlyExpenses(String businessId);
  Future<double> getYearlyExpenses(String businessId);
  Future<Map<String, double>> getExpenseByCategory(String businessId);
  Future<String> generateExpenseNumber(String businessId, String prefix);
}
