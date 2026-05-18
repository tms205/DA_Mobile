import 'package:flutter/foundation.dart' hide Category;
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
import '../data/models/transaction_model.dart';
import '../data/database/app_database.dart';

class BudgetProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<Budget> _budgets = [];
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  List<Budget> get activeBudgets => _budgets.where((b) => b.isActive).toList();
  List<Budget> get exceededBudgets =>
      _budgets.where((b) => b.isExceeded).toList();
  List<Budget> get warningBudgets =>
      _budgets.where((b) => b.isWarning).toList();

  Future<void> loadBudgets() async {
    _isLoading = true;
    notifyListeners();
    try {
      _budgets = await _db.getBudgets();
      _categories = await _db.getCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBudget(Budget b) async {
    await _db.insertBudget(b);
    await refreshBudgetSpending();
  }

  Future<void> updateBudget(Budget b) async {
    await _db.updateBudget(b);
    await refreshBudgetSpending();
  }

  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
    await loadBudgets();
  }

  Future<void> refreshBudgetSpending() async {
    final latestBudgets = await _db.getBudgets();
    for (final budget in latestBudgets.where((b) => b.isActive)) {
      final transactions = await _db.getTransactions(
        startDate: budget.startDate,
        endDate: budget.endDate,
        categoryId: budget.categoryId,
        type: TransactionType.expense,
      );
      final spent = transactions.fold<double>(0, (sum, t) => sum + t.amount);
      await _db.updateBudgetSpent(budget.id, spent);
    }
    await loadBudgets();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  double get totalBudgetLimit => _budgets.fold(0.0, (sum, b) => sum + b.limit);
  double get totalBudgetSpent => _budgets.fold(0.0, (sum, b) => sum + b.spent);
}
