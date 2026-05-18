import 'package:flutter/foundation.dart';
import '../data/models/account_model.dart';
import '../data/database/app_database.dart';

class AccountProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<Account> _accounts = [];
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;

  double get totalBalance => _accounts.fold(0.0, (sum, a) => sum + a.balance);
  int get totalAccounts => _accounts.length;
  int get activeWallets => _accounts.where((a) => a.balance >= 0).length;

  Account? get defaultAccount {
    try { return _accounts.firstWhere((a) => a.isDefault); }
    catch (_) { return _accounts.isNotEmpty ? _accounts.first : null; }
  }

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _accounts = await _db.getAccounts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAccount(Account a) async {
    final account = a.copyWith(isDefault: a.isDefault || _accounts.isEmpty);
    await _db.insertAccount(account);
    await loadAccounts();
  }

  Future<void> updateAccount(Account a) async {
    await _db.updateAccount(a);
    await loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await _db.deleteAccount(id);
    await loadAccounts();
  }

  Account? getById(String id) {
    try { return _accounts.firstWhere((a) => a.id == id); }
    catch (_) { return null; }
  }

  Map<AccountType, List<Account>> get groupedByType {
    final map = <AccountType, List<Account>>{};
    for (final a in _accounts) {
      map.putIfAbsent(a.type, () => []).add(a);
    }
    return map;
  }
}
