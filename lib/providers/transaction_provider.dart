import 'package:flutter/foundation.dart' hide Category;
import '../data/models/transaction_model.dart';
import '../data/models/category_model.dart';
import '../data/models/account_model.dart';
import '../data/database/app_database.dart';
import '../data/services/recurring_transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  late final RecurringTransactionService _recurringService =
      RecurringTransactionService(database: _db);

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];

  bool _isLoading = false;
  String _searchQuery = '';
  TransactionType? _filterType;
  String? _filterCategoryId;
  String? _filterAccountId;
  // ── Getters ──────────────────────────────────────────────────
  List<Transaction> get transactions => _filteredTransactions;
  List<Transaction> get allTransactions => _transactions;
  List<Category> get categories => _categories;
  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  TransactionType? get filterType => _filterType;

  List<Transaction> get _filteredTransactions {
    var list = _transactions;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (t) => t.note.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_filterType != null) {
      list = list.where((t) => t.type == _filterType).toList();
    }
    if (_filterCategoryId != null) {
      list = list.where((t) => t.categoryId == _filterCategoryId).toList();
    }
    if (_filterAccountId != null) {
      list = list.where((t) => t.accountId == _filterAccountId).toList();
    }
    return list;
  }

  // ── Thống kê nhanh ──────────────────────────────────────────
  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalBalance => totalIncome - totalExpense;

  List<Transaction> get recentTransactions => _transactions.take(10).toList();

  /// Nhóm giao dịch theo ngày
  Map<DateTime, List<Transaction>> get transactionsByDate {
    final map = <DateTime, List<Transaction>>{};
    for (final t in _filteredTransactions) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  // ── Load Data ────────────────────────────────────────────────
  Future<void> loadAll({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _recurringService.generateDueTransactions();
      _transactions = await _db.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      _categories = await _db.getCategories();
      _accounts = await _db.getAccounts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactionsForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(
      year,
      month + 1,
      1,
    ).subtract(const Duration(seconds: 1));
    await loadAll(startDate: start, endDate: end);
  }

  Future<List<Transaction>> fetchTransactionsForMonth(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(
      year,
      month + 1,
      1,
    ).subtract(const Duration(seconds: 1));
    return _db.getTransactions(startDate: start, endDate: end);
  }

  Future<List<Transaction>> fetchTransactionsForYear(int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1).subtract(const Duration(seconds: 1));
    return _db.getTransactions(startDate: start, endDate: end);
  }

  // ── Add / Update / Delete ────────────────────────────────────
  Future<void> addTransaction(Transaction t) async {
    await _db.insertTransaction(t);
    // Cập nhật số dư tài khoản
    await _updateAccountBalance(t);
    await loadAll();
  }

  Future<void> updateTransaction(Transaction oldT, Transaction newT) async {
    await _db.updateTransaction(newT);
    // Revert old + apply new balance change
    await _revertAccountBalance(oldT);
    await _updateAccountBalance(newT);
    await loadAll();
  }

  Future<void> deleteTransaction(Transaction t) async {
    await _db.deleteTransaction(t.id);
    await _revertAccountBalance(t);
    await loadAll();
  }

  Future<void> _updateAccountBalance(Transaction t) async {
    final accounts = _accounts.isNotEmpty ? _accounts : await _db.getAccounts();
    if (accounts.isEmpty) return;

    final acc = accounts.firstWhere(
      (a) => a.id == t.accountId,
      orElse: () => accounts.first,
    );
    double newBalance = acc.balance;
    if (t.type == TransactionType.income) {
      newBalance += t.amount;
    } else if (t.type == TransactionType.expense) {
      newBalance -= t.amount;
    } else if (t.type == TransactionType.transfer) {
      newBalance -= t.amount;
      if (t.toAccountId != null) {
        final toAcc = accounts.firstWhere(
          (a) => a.id == t.toAccountId!,
          orElse: () => acc,
        );
        await _db.updateAccountBalance(
          t.toAccountId!,
          toAcc.balance + t.amount,
        );
      }
    }
    await _db.updateAccountBalance(t.accountId, newBalance);
  }

  Future<void> _revertAccountBalance(Transaction t) async {
    final accounts = await _db.getAccounts();
    if (accounts.isEmpty) return;

    final acc = accounts.firstWhere(
      (a) => a.id == t.accountId,
      orElse: () => accounts.first,
    );
    double newBalance = acc.balance;
    if (t.type == TransactionType.income) {
      newBalance -= t.amount;
    } else if (t.type == TransactionType.expense) {
      newBalance += t.amount;
    } else if (t.type == TransactionType.transfer) {
      newBalance += t.amount;
      if (t.toAccountId != null) {
        final toAcc = accounts.firstWhere(
          (a) => a.id == t.toAccountId!,
          orElse: () => acc,
        );
        await _db.updateAccountBalance(
          t.toAccountId!,
          toAcc.balance - t.amount,
        );
      }
    }
    await _db.updateAccountBalance(t.accountId, newBalance);
  }

  // ── Category Helpers ─────────────────────────────────────────
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Account? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Filters ──────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterType = null;
    _filterCategoryId = null;
    _filterAccountId = null;
    notifyListeners();
  }

  // ── Expense by category ──────────────────────────────────────
  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final t in _transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  /// Chi tiêu theo tháng trong năm
  List<double> monthlyExpenses(int year) {
    final list = List<double>.filled(12, 0.0);
    for (final t in _transactions.where(
      (t) => t.type == TransactionType.expense && t.date.year == year,
    )) {
      list[t.date.month - 1] += t.amount;
    }
    return list;
  }

  List<double> monthlyIncome(int year) {
    final list = List<double>.filled(12, 0.0);
    for (final t in _transactions.where(
      (t) => t.type == TransactionType.income && t.date.year == year,
    )) {
      list[t.date.month - 1] += t.amount;
    }
    return list;
  }
}
