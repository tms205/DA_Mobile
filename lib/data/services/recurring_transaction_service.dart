import '../database/app_database.dart';
import '../models/transaction_model.dart';

class RecurringTransactionService {
  RecurringTransactionService({AppDatabase? database}) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<int> generateDueTransactions({DateTime? now}) async {
    final today = _dateOnly(now ?? DateTime.now());
    final transactions = await _database.getTransactions();
    final recurring = transactions
        .where((t) => t.isRecurring && t.recurringInterval != null)
        .toList();
    var generated = 0;

    for (final template in recurring) {
      var nextDate = _nextDate(template.date, template.recurringInterval!);
      var guard = 0;
      while (!nextDate.isAfter(today) && guard < 36) {
        if (!_alreadyGenerated(transactions, template, nextDate)) {
          final copy = Transaction(
            type: template.type,
            amount: template.amount,
            categoryId: template.categoryId,
            accountId: template.accountId,
            toAccountId: template.toAccountId,
            note: _generatedNote(template),
            date: nextDate,
            receiptImagePath: template.receiptImagePath,
          );
          await _database.insertTransaction(copy);
          await _applyBalance(copy);
          transactions.add(copy);
          generated++;
        }
        nextDate = _nextDate(nextDate, template.recurringInterval!);
        guard++;
      }
    }

    return generated;
  }

  bool _alreadyGenerated(List<Transaction> transactions, Transaction template, DateTime date) {
    final note = _generatedNote(template);
    return transactions.any((t) {
      final sameDay = _dateOnly(t.date) == _dateOnly(date);
      return sameDay &&
          !t.isRecurring &&
          t.type == template.type &&
          t.amount == template.amount &&
          t.categoryId == template.categoryId &&
          t.accountId == template.accountId &&
          t.toAccountId == template.toAccountId &&
          t.note == note;
    });
  }

  Future<void> _applyBalance(Transaction transaction) async {
    final accounts = await _database.getAccounts();
    if (accounts.isEmpty) return;

    final account = accounts.firstWhere(
      (a) => a.id == transaction.accountId,
      orElse: () => accounts.first,
    );
    var newBalance = account.balance;
    switch (transaction.type) {
      case TransactionType.income:
        newBalance += transaction.amount;
      case TransactionType.expense:
        newBalance -= transaction.amount;
      case TransactionType.transfer:
        newBalance -= transaction.amount;
        if (transaction.toAccountId != null) {
          final toAccount = accounts.firstWhere(
            (a) => a.id == transaction.toAccountId,
            orElse: () => account,
          );
          await _database.updateAccountBalance(
            transaction.toAccountId!,
            toAccount.balance + transaction.amount,
          );
        }
    }
    await _database.updateAccountBalance(transaction.accountId, newBalance);
  }

  DateTime _nextDate(DateTime from, String interval) {
    final date = _dateOnly(from);
    switch (interval) {
      case 'daily':
        return date.add(const Duration(days: 1));
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(date.year, date.month + 1, date.day);
      default:
        return date.add(const Duration(days: 1));
    }
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _generatedNote(Transaction template) {
    final base = template.note.trim().isEmpty ? 'Giao dịch định kỳ' : template.note.trim();
    return '[Tự động] $base';
  }
}
