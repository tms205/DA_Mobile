import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ltdd_nhom9/core/constants/app_strings.dart';
import 'package:ltdd_nhom9/data/database/app_database.dart';
import 'package:ltdd_nhom9/data/models/account_model.dart';
import 'package:ltdd_nhom9/data/models/budget_model.dart';
import 'package:ltdd_nhom9/data/models/category_model.dart';
import 'package:ltdd_nhom9/data/models/transaction_model.dart';
import 'package:ltdd_nhom9/data/services/receipt_parser.dart';
import 'package:ltdd_nhom9/data/services/smart_finance_service.dart';
import 'package:ltdd_nhom9/providers/budget_provider.dart';

void main() {
  test('app strings are configured', () {
    expect(AppStrings.appName, 'Quản Lý Chi Tiêu');
    expect(AppStrings.navTransactions, 'Giao dịch');
  });

  test('receipt parser extracts the largest amount', () {
    final draft = ReceiptParser.parse(
      'Cửa hàng ABC\nMì: 35.000\nTổng cộng: 125.000',
    );

    expect(draft.amount, 125000);
    expect(draft.note, 'OCR: Cửa hàng ABC');
  });

  test('local storage can create an account', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase();
    await database.replaceData({
      'transactions': [],
      'categories': [],
      'accounts': [],
      'budgets': [],
    });

    await database.insertAccount(
      Account(
        name: 'Ví test',
        type: AccountType.cash,
        balance: 500000,
        color: 0xFF1A6B3C,
        icon: '${57490}',
        isDefault: true,
      ),
    );

    final accounts = await database.getAccounts();
    expect(accounts.any((account) => account.name == 'Ví test'), isTrue);
  });

  test(
    'budget recalculates spending when created after transactions',
    () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase();
      await database.replaceData({
        'transactions': [],
        'categories': [],
        'accounts': [],
        'budgets': [],
      });

      final now = DateTime.now();
      await database.insertTransaction(
        Transaction(
          type: TransactionType.expense,
          amount: 125000,
          categoryId: 'cat_food',
          accountId: 'acc_default',
          note: 'Ăn trưa',
          date: now,
        ),
      );

      final provider = BudgetProvider();
      await provider.addBudget(
        Budget(
          categoryId: 'cat_food',
          limit: 1000000,
          period: BudgetPeriod.monthly,
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(
            now.year,
            now.month + 1,
            1,
          ).subtract(const Duration(seconds: 1)),
        ),
      );

      expect(provider.totalBudgetLimit, 1000000);
      expect(provider.totalBudgetSpent, 125000);
    },
  );

  test(
    'smart classifier suggests expense categories from Vietnamese notes',
    () {
      final categories = DefaultCategories.all;

      final fuel = SmartExpenseClassifier.suggestExpenseCategory(
        'Đổ xăng 100k',
        categories,
      );
      final game = SmartExpenseClassifier.suggestExpenseCategory(
        'Mua skin Valorant',
        categories,
      );

      expect(fuel?.categoryId, 'cat_transport');
      expect(game?.categoryId, 'cat_entertainment');
    },
  );

  test('smart classifier suggests income categories from Vietnamese notes', () {
    final categories = DefaultCategories.all;

    final salary = SmartExpenseClassifier.suggestCategory(
      'Nhận lương tháng này',
      categories,
      type: TransactionType.income,
    );
    final bonus = SmartExpenseClassifier.suggestCategory(
      'Thưởng dự án 500k',
      categories,
      type: TransactionType.income,
    );

    expect(salary?.categoryId, 'cat_salary');
    expect(bonus?.categoryId, 'cat_bonus');
  });

  test('smart forecast projects end of month expense', () {
    final selectedMonth = DateTime(2026, 4, 1);
    final transactions = [
      Transaction(
        type: TransactionType.income,
        amount: 3000000,
        categoryId: 'cat_salary',
        accountId: 'acc_default',
        date: selectedMonth,
      ),
      Transaction(
        type: TransactionType.expense,
        amount: 1000000,
        categoryId: 'cat_food',
        accountId: 'acc_default',
        date: selectedMonth,
      ),
    ];

    final forecast = SmartFinanceService.buildForecast(
      currentMonth: transactions,
      selectedMonth: selectedMonth,
    );

    expect(forecast.projectedExpense, closeTo(1000000, 0.01));
    expect(forecast.projectedSaving, closeTo(2000000, 0.01));
  });

  test('financial assistant answers top expense question', () {
    final response = FinancialAssistantService.answer(
      question: 'Tháng này tôi tiêu gì nhiều nhất?',
      currentMonth: [
        Transaction(
          type: TransactionType.expense,
          amount: 200000,
          categoryId: 'cat_food',
          accountId: 'acc_default',
          date: DateTime(2026, 5, 1),
        ),
        Transaction(
          type: TransactionType.expense,
          amount: 100000,
          categoryId: 'cat_transport',
          accountId: 'acc_default',
          date: DateTime(2026, 5, 2),
        ),
      ],
      previousMonth: const [],
      categories: DefaultCategories.all,
      accounts: const [],
      budgets: const [],
      selectedMonth: DateTime(2026, 5, 1),
    );

    expect(response.answer, contains('Ăn uống'));
  });
}
