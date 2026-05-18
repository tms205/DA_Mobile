import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static const _storageKey = 'finance_app_store_v2';

  Map<String, List<Map<String, dynamic>>>? _cache;

  Future<Map<String, List<Map<String, dynamic>>>> get _store async {
    if (_cache != null) return _cache!;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = _defaultStore();
      await _save();
      return _cache!;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cache = _normalizeStore(decoded);
    _ensureDefaults(_cache!);
    await _save();
    return _cache!;
  }

  Future<void> _save() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_cache));
  }

  Map<String, List<Map<String, dynamic>>> _defaultStore() {
    final defaultAccount = Account(
      id: 'acc_default',
      name: 'Ví tiền mặt',
      type: AccountType.cash,
      balance: 0,
      color: 0xFF1A6B3C,
      icon: '${57490}',
      isDefault: true,
    );
    final bankAccount = Account(
      id: 'acc_bank',
      name: 'Tài khoản ngân hàng',
      type: AccountType.bank,
      balance: 0,
      color: 0xFF29B6F6,
      icon: '${57481}',
    );

    return {
      'transactions': <Map<String, dynamic>>[],
      'categories': DefaultCategories.all.map((c) => c.toMap()).toList(),
      'accounts': [defaultAccount.toMap(), bankAccount.toMap()],
      'budgets': <Map<String, dynamic>>[],
    };
  }

  Map<String, List<Map<String, dynamic>>> _normalizeStore(
    Map<String, dynamic> decoded,
  ) {
    List<Map<String, dynamic>> table(String name) {
      final rows = decoded[name];
      if (rows is! List) return <Map<String, dynamic>>[];
      return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
    }

    return {
      'transactions': table('transactions'),
      'categories': table('categories'),
      'accounts': table('accounts'),
      'budgets': table('budgets'),
    };
  }

  void _ensureDefaults(Map<String, List<Map<String, dynamic>>> store) {
    if (store['accounts']!.isEmpty) {
      store['accounts']!.addAll(_defaultStore()['accounts']!);
    }
    if (store['categories']!.isEmpty) {
      store['categories']!.addAll(DefaultCategories.all.map((c) => c.toMap()));
    }
  }

  List<Map<String, dynamic>> _table(
    Map<String, List<Map<String, dynamic>>> store,
    String name,
  ) {
    return store.putIfAbsent(name, () => <Map<String, dynamic>>[]);
  }

  // Transactions
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
    TransactionType? type,
  }) async {
    final store = await _store;
    final rows =
        _table(store, 'transactions').where((row) {
          final date = DateTime.parse(row['date'] as String);
          if (startDate != null && date.isBefore(startDate)) return false;
          if (endDate != null && date.isAfter(endDate)) return false;
          if (categoryId != null && row['categoryId'] != categoryId) {
            return false;
          }
          if (accountId != null && row['accountId'] != accountId) return false;
          if (type != null && row['type'] != type.name) return false;
          return true;
        }).toList()..sort(
          (a, b) => (b['date'] as String).compareTo(a['date'] as String),
        );

    return rows.map(Transaction.fromMap).toList();
  }

  Future<void> insertTransaction(Transaction transaction) async {
    final store = await _store;
    final rows = _table(store, 'transactions');
    rows.removeWhere((row) => row['id'] == transaction.id);
    rows.add(transaction.toMap());
    await _save();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await insertTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    final store = await _store;
    _table(store, 'transactions').removeWhere((row) => row['id'] == id);
    await _save();
  }

  // Categories
  Future<List<Category>> getCategories({bool? isIncome}) async {
    final store = await _store;
    final rows = _table(store, 'categories').where((row) {
      if (isIncome == null) return true;
      return row['isIncome'] == (isIncome ? 1 : 0);
    }).toList();
    return rows.map(Category.fromMap).toList();
  }

  Future<void> insertCategory(Category category) async {
    final store = await _store;
    final rows = _table(store, 'categories');
    rows.removeWhere((row) => row['id'] == category.id);
    rows.add(category.toMap());
    await _save();
  }

  Future<void> updateCategory(Category category) async {
    await insertCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    final store = await _store;
    _table(store, 'categories').removeWhere((row) => row['id'] == id);
    await _save();
  }

  // Accounts
  Future<List<Account>> getAccounts() async {
    final store = await _store;
    final rows = [..._table(store, 'accounts')]
      ..sort((a, b) {
        final defaultCompare = (b['isDefault'] as int).compareTo(
          a['isDefault'] as int,
        );
        if (defaultCompare != 0) return defaultCompare;
        return (a['createdAt'] as String).compareTo(b['createdAt'] as String);
      });
    return rows.map(Account.fromMap).toList();
  }

  Future<void> insertAccount(Account account) async {
    final store = await _store;
    final rows = _table(store, 'accounts');
    if (account.isDefault) {
      for (final row in rows) {
        row['isDefault'] = 0;
      }
    }
    rows.removeWhere((row) => row['id'] == account.id);
    rows.add(account.toMap());
    await _save();
  }

  Future<void> updateAccount(Account account) async {
    await insertAccount(account);
  }

  Future<void> deleteAccount(String id) async {
    final store = await _store;
    final rows = _table(store, 'accounts');
    final removedWasDefault = rows.any(
      (row) => row['id'] == id && row['isDefault'] == 1,
    );
    rows.removeWhere((row) => row['id'] == id);
    if (removedWasDefault && rows.isNotEmpty) {
      rows.first['isDefault'] = 1;
    }
    await _save();
  }

  Future<void> updateAccountBalance(String id, double newBalance) async {
    final store = await _store;
    final rows = _table(store, 'accounts');
    final index = rows.indexWhere((row) => row['id'] == id);
    if (index == -1) return;
    rows[index] = {
      ...rows[index],
      'balance': newBalance,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _save();
  }

  // Budgets
  Future<List<Budget>> getBudgets({bool? isActive}) async {
    final store = await _store;
    final rows = _table(store, 'budgets').where((row) {
      if (isActive == null) return true;
      return row['isActive'] == (isActive ? 1 : 0);
    }).toList();
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> insertBudget(Budget budget) async {
    final store = await _store;
    final rows = _table(store, 'budgets');
    rows.removeWhere((row) => row['id'] == budget.id);
    rows.add(budget.toMap());
    await _save();
  }

  Future<void> updateBudget(Budget budget) async {
    await insertBudget(budget);
  }

  Future<void> deleteBudget(String id) async {
    final store = await _store;
    _table(store, 'budgets').removeWhere((row) => row['id'] == id);
    await _save();
  }

  Future<void> updateBudgetSpent(String budgetId, double spent) async {
    final store = await _store;
    final rows = _table(store, 'budgets');
    for (var i = 0; i < rows.length; i++) {
      if (rows[i]['id'] == budgetId && rows[i]['isActive'] == 1) {
        rows[i] = {
          ...rows[i],
          'spent': spent,
          'updatedAt': DateTime.now().toIso8601String(),
        };
      }
    }
    await _save();
  }

  // Aggregates
  Future<double> getTotalByType(
    TransactionType type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
    return transactions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  Future<Map<String, double>> getExpenseByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      startDate: startDate,
      endDate: endDate,
      type: TransactionType.expense,
    );
    final result = <String, double>{};
    for (final transaction in transactions) {
      result[transaction.categoryId] =
          (result[transaction.categoryId] ?? 0) + transaction.amount;
    }
    return result;
  }

  Future<Map<String, List<Map<String, dynamic>>>> exportData() async {
    final store = await _store;
    return store.map((table, rows) {
      return MapEntry(
        table,
        rows.map((row) => Map<String, dynamic>.from(row)).toList(),
      );
    });
  }

  Future<void> replaceData(Map<String, List<Map<String, dynamic>>> data) async {
    _cache = {
      'transactions': data['transactions'] ?? <Map<String, dynamic>>[],
      'categories': data['categories'] ?? <Map<String, dynamic>>[],
      'accounts': data['accounts'] ?? <Map<String, dynamic>>[],
      'budgets': data['budgets'] ?? <Map<String, dynamic>>[],
    };
    _ensureDefaults(_cache!);
    await _save();
  }
}
