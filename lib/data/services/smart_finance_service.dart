import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

String _normalizeVietnameseText(String value) {
  const marks = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };

  final buffer = StringBuffer();
  for (final codePoint in value.toLowerCase().runes) {
    final char = String.fromCharCode(codePoint);
    buffer.write(marks[char] ?? char);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class CategorySuggestion {
  const CategorySuggestion({
    required this.categoryId,
    required this.confidence,
    required this.reason,
  });

  final String categoryId;
  final double confidence;
  final String reason;
}

class SmartExpenseClassifier {
  SmartExpenseClassifier._();

  static const Map<String, List<String>> _keywords = {
    'cat_food': [
      'an sang',
      'an trua',
      'an toi',
      'do an',
      'an vat',
      'com',
      'com tam',
      'com ga',
      'com van phong',
      'pho',
      'bun bo',
      'bun cha',
      'hu tieu',
      'banh mi',
      'mi cay',
      'lau',
      'nuong',
      'tra sua',
      'tra chanh',
      'nuoc ep',
      'sinh to',
      'ca phe',
      'coffee',
      'cafe',
      'highlands',
      'phuc long',
      'the coffee house',
      'starbucks',
      'quan an',
      'nha hang',
      'restaurant',
      'grabfood',
      'shopeefood',
      'befood',
      'gofood',
    ],
    'cat_transport': [
      'grab',
      'grab bike',
      'grabcar',
      'grab car',
      'xanhsm',
      'xanh sm',
      'be',
      'be bike',
      'becar',
      'be car',
      'gojek',
      'xe om',
      'xe cong nghe',
      'taxi',
      'mai linh',
      'vinasun',
      'vinbus',
      'bus',
      'buyt',
      'metro',
      'tau dien',
      've xe',
      'do xang',
      'xang',
      'sac xe',
      'gui xe',
      'giu xe',
      'phi cau duong',
      'tram thu phi',
      'cao toc',
      'di chuyen',
    ],
    'cat_shopping': [
      'mua sam',
      'shopee',
      'lazada',
      'tiki',
      'sendo',
      'quan ao',
      'thoi trang',
      'giay dep',
      'tui xach',
      'my pham',
      'phu kien',
      'do gia dung',
      'dien may',
      'dien thoai',
      'tablet',
      'laptop',
      'airpods',
    ],
    'cat_entertainment': [
      'game',
      'valorant',
      'skin',
      'netflix',
      'spotify',
      'youtube premium',
      'apple music',
      'steam',
      'cgv',
      'lotte cinema',
      'galaxy cinema',
      'beta cinema',
      'phim',
      'rap phim',
      'cinema',
      'karaoke',
      'giai tri',
      'ca nhac',
      'concert',
    ],
    'cat_health': [
      'thuoc',
      'nha thuoc',
      'long chau',
      'pharmacity',
      'an khang',
      'benh vien',
      'phong kham',
      'kham benh',
      'xet nghiem',
      'vien phi',
      'bac si',
      'y te',
      'nha khoa',
      'kham rang',
      'mat kinh',
    ],
    'cat_education': [
      'hoc phi',
      'hoc them',
      'gia su',
      'khoa hoc',
      'tai lieu',
      'sach',
      'vo',
      'udemy',
      'coursera',
      'ielts',
      'toeic',
      'tieng anh',
      'on thi',
      'trung tam',
    ],
    'cat_bills': [
      'tien dien',
      'dien luc',
      'evn',
      'tien nuoc',
      'cap nuoc',
      'wifi',
      'internet',
      'fpt',
      'viettel',
      'vnpt',
      'hoa don',
      'cuoc dien thoai',
      'tra sau',
      'sim',
      'bao hiem',
      'gas',
      'phi dich vu',
      'truyen hinh',
    ],
    'cat_housing': [
      'tien nha',
      'thue nha',
      'phong tro',
      'tien tro',
      'chung cu',
      'can ho',
      'coc nha',
      'coc phong',
      'noi that',
      'sua phong',
      'sua nha',
      'nha o',
    ],
  };

  static const Map<String, List<String>> _incomeKeywords = {
    'cat_salary': [
      'luong',
      'salary',
      'payroll',
      'cong ty tra',
      'cong ty chuyen luong',
      'nhan luong',
      'luong thang',
      'luong co ban',
    ],
    'cat_bonus': [
      'thuong',
      'bonus',
      'commission',
      'hoa hong',
      'phu cap',
      'tet',
      'thuong doanh so',
      'thuong nong',
    ],
    'cat_freelance': [
      'freelance',
      'lam them',
      'du an',
      'nhan job',
      'khach tra',
      'khach chuyen tien',
      'viet content',
      'thiet ke',
      'code web',
    ],
    'cat_investment': [
      'dau tu',
      'co tuc',
      'lai ngan hang',
      'lai tiet kiem',
      'chung khoan',
      'ban co phieu',
      'crypto',
      'staking',
      'trade',
    ],
    'cat_other_income': [
      'nhan tien',
      'chuyen khoan ve',
      'duoc tang',
      'hoan tien',
      'refund',
      'ban do cu',
      'thu no',
      'thu hoi cong no',
    ],
  };

  static CategorySuggestion? suggestCategory(
    String text,
    List<Category> categories, {
    required TransactionType type,
  }) {
    return switch (type) {
      TransactionType.income => _suggestByKeywords(
        text,
        categories,
        isIncome: true,
        keywords: _incomeKeywords,
      ),
      TransactionType.expense => suggestExpenseCategory(text, categories),
      TransactionType.transfer => null,
    };
  }

  static CategorySuggestion? suggestExpenseCategory(
    String text,
    List<Category> categories,
  ) {
    return _suggestByKeywords(
      text,
      categories,
      isIncome: false,
      keywords: _keywords,
    );
  }

  static CategorySuggestion? _suggestByKeywords(
    String text,
    List<Category> categories, {
    required bool isIncome,
    required Map<String, List<String>> keywords,
  }) {
    final normalized = _normalize(text);
    if (normalized.trim().isEmpty) return null;

    final availableCategories = categories
        .where((category) => category.isIncome == isIncome)
        .toList();
    final availableById = {
      for (final category in availableCategories) category.id: category,
    };
    final scores = <String, int>{};
    final hitsById = <String, Set<String>>{};

    void addMatch(String categoryId, String hit, int score) {
      if (!availableById.containsKey(categoryId)) return;
      scores[categoryId] = (scores[categoryId] ?? 0) + score;
      hitsById.putIfAbsent(categoryId, () => <String>{}).add(hit);
    }

    for (final category in availableCategories) {
      final normalizedName = _normalize(category.name);
      if (normalizedName.length >= 3 && normalized.contains(normalizedName)) {
        addMatch(
          category.id,
          'ten danh muc: ${category.name}',
          normalizedName.contains(' ') ? 4 : 3,
        );
      }
    }

    for (final entry in keywords.entries) {
      for (final keyword in entry.value) {
        final normalizedKeyword = _normalize(keyword);
        if (normalized.contains(normalizedKeyword)) {
          addMatch(
            entry.key,
            keyword,
            _keywordScore(normalized, normalizedKeyword),
          );
        }
      }
    }

    if (scores.isEmpty) return null;

    var bestId = '';
    var bestScore = 0;
    scores.forEach((categoryId, score) {
      if (score > bestScore) {
        bestId = categoryId;
        bestScore = score;
      }
    });

    final matched = (hitsById[bestId] ?? const <String>{}).take(3).join(', ');
    return CategorySuggestion(
      categoryId: bestId,
      confidence: min(0.96, 0.45 + bestScore * 0.08),
      reason: matched.isEmpty ? 'khop bo tu khoa' : 'khop: $matched',
    );
  }

  static int _keywordScore(String text, String keyword) {
    var score = keyword.contains(' ') ? 3 : (keyword.length >= 8 ? 2 : 1);
    if (text == keyword || text.startsWith('$keyword ')) {
      score += 1;
    }
    return score;
  }

  static String _normalize(String value) {
    return _normalizeVietnameseText(value);
  }
}

class SmartFinanceInsight {
  const SmartFinanceInsight({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}

class SmartBadge {
  const SmartBadge({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
}

class ForecastResult {
  const ForecastResult({
    required this.projectedExpense,
    required this.projectedSaving,
    required this.averageDailyExpense,
    required this.daysRemaining,
  });

  final double projectedExpense;
  final double projectedSaving;
  final double averageDailyExpense;
  final int daysRemaining;
}

class SmartFinanceService {
  SmartFinanceService._();

  static List<SmartFinanceInsight> buildInsights({
    required List<Transaction> currentMonth,
    required List<Transaction> previousMonth,
    required List<Category> categories,
    required DateTime selectedMonth,
  }) {
    final insights = <SmartFinanceInsight>[];
    final currentExpense = _sumByType(currentMonth, TransactionType.expense);
    final previousExpense = _sumByType(previousMonth, TransactionType.expense);
    final currentIncome = _sumByType(currentMonth, TransactionType.income);

    if (currentExpense > 0 && previousExpense > 0) {
      final change =
          ((currentExpense - previousExpense) / previousExpense) * 100;
      if (change.abs() >= 10) {
        insights.add(
          SmartFinanceInsight(
            title: change > 0 ? 'Chi tiêu tăng' : 'Chi tiêu giảm',
            message:
                'Tháng này bạn ${change > 0 ? 'chi nhiều hơn' : 'chi ít hơn'} ${change.abs().toStringAsFixed(1)}% so với tháng trước.',
            icon: change > 0 ? Icons.trending_up : Icons.trending_down,
            color: change > 0 ? AppColors.warning : AppColors.income,
          ),
        );
      }
    }

    final categoryTotals = _expenseByCategory(currentMonth);
    if (categoryTotals.isNotEmpty) {
      final top = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topEntry = top.first;
      final categoryName =
          categories
              .where((category) => category.id == topEntry.key)
              .firstOrNull
              ?.name ??
          'một danh mục';
      final pct = currentExpense > 0
          ? topEntry.value / currentExpense * 100
          : 0;
      insights.add(
        SmartFinanceInsight(
          title: 'Danh mục nổi bật',
          message:
              '$categoryName đang chiếm ${pct.toStringAsFixed(1)}% tổng chi tiêu tháng này.',
          icon: Icons.pie_chart_rounded,
          color: AppColors.info,
        ),
      );
    }

    final weekendExpense = _weekendExpense(currentMonth);
    if (currentExpense > 0 && weekendExpense / currentExpense >= 0.45) {
      insights.add(
        SmartFinanceInsight(
          title: 'Cuối tuần chi cao',
          message:
              'Chi tiêu cuối tuần chiếm ${(weekendExpense / currentExpense * 100).toStringAsFixed(1)}% tháng này.',
          icon: Icons.weekend_rounded,
          color: AppColors.warning,
        ),
      );
    }

    final anomaly = _largestAnomaly(currentMonth);
    if (anomaly != null) {
      insights.add(
        SmartFinanceInsight(
          title: 'Chi tiêu bất thường',
          message:
              '${DateFormatter.formatDate(anomaly.key)} cao hơn mức trung bình ngày khoảng ${anomaly.value.toStringAsFixed(1)} lần.',
          icon: Icons.notification_important_rounded,
          color: AppColors.expense,
        ),
      );
    }

    if (currentIncome > 0) {
      final savingRate = (currentIncome - currentExpense) / currentIncome * 100;
      if (savingRate >= 20) {
        insights.add(
          SmartFinanceInsight(
            title: 'Tiết kiệm tốt',
            message:
                'Bạn đang giữ tỷ lệ tiết kiệm ${savingRate.toStringAsFixed(1)}%. Tiếp tục nhịp này là rất ổn.',
            icon: Icons.savings_rounded,
            color: AppColors.income,
          ),
        );
      }
    }

    if (insights.isEmpty) {
      insights.add(
        const SmartFinanceInsight(
          title: 'Chưa đủ dữ liệu',
          message:
              'Hãy ghi thêm giao dịch để app phân tích xu hướng, bất thường và dự đoán cuối tháng.',
          icon: Icons.auto_awesome_rounded,
          color: AppColors.primary,
        ),
      );
    }

    return insights.take(5).toList();
  }

  static ForecastResult buildForecast({
    required List<Transaction> currentMonth,
    required DateTime selectedMonth,
  }) {
    final expense = _sumByType(currentMonth, TransactionType.expense);
    final income = _sumByType(currentMonth, TransactionType.income);
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final lastDay = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;
    final elapsedDays = isCurrentMonth ? max(1, now.day) : lastDay;
    final daysRemaining = isCurrentMonth ? max(0, lastDay - now.day) : 0;
    final averageDailyExpense = expense / elapsedDays;
    final projectedExpense = averageDailyExpense * lastDay;

    return ForecastResult(
      projectedExpense: projectedExpense,
      projectedSaving: income - projectedExpense,
      averageDailyExpense: averageDailyExpense,
      daysRemaining: daysRemaining,
    );
  }

  static List<SmartBadge> buildBadges(List<Transaction> currentMonth) {
    final expense = _sumByType(currentMonth, TransactionType.expense);
    final income = _sumByType(currentMonth, TransactionType.income);
    final foodExpense = currentMonth
        .where(
          (t) =>
              t.type == TransactionType.expense && t.categoryId == 'cat_food',
        )
        .fold<double>(0, (sum, t) => sum + t.amount);
    final savingRate = income > 0 ? (income - expense) / income : 0.0;
    final activeDays = currentMonth
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .length;

    return [
      SmartBadge(
        title: 'Budget Starter',
        description: 'Có ít nhất 5 ngày ghi chép giao dịch.',
        icon: Icons.flag_rounded,
        color: AppColors.info,
        unlocked: activeDays >= 5,
      ),
      SmartBadge(
        title: 'Tiết kiệm Master',
        description: 'Tỷ lệ tiết kiệm tháng này từ 20% trở lên.',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.accentGold,
        unlocked: savingRate >= 0.2,
      ),
      SmartBadge(
        title: 'Ăn uống có kiểm soát',
        description: 'Ăn uống dưới 35% tổng chi tiêu.',
        icon: Icons.restaurant_menu_rounded,
        color: AppColors.income,
        unlocked: expense > 0 && foodExpense / expense <= 0.35,
      ),
    ];
  }

  static double _sumByType(
    List<Transaction> transactions,
    TransactionType type,
  ) {
    return transactions
        .where((transaction) => transaction.type == type)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  static Map<String, double> _expenseByCategory(
    List<Transaction> transactions,
  ) {
    final result = <String, double>{};
    for (final transaction in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      result[transaction.categoryId] =
          (result[transaction.categoryId] ?? 0) + transaction.amount;
    }
    return result;
  }

  static double _weekendExpense(List<Transaction> transactions) {
    return transactions
        .where((transaction) {
          final day = transaction.date.weekday;
          return transaction.type == TransactionType.expense &&
              (day == DateTime.saturday || day == DateTime.sunday);
        })
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  static MapEntry<DateTime, double>? _largestAnomaly(
    List<Transaction> transactions,
  ) {
    final daily = <DateTime, double>{};
    for (final transaction in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      final key = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      daily[key] = (daily[key] ?? 0) + transaction.amount;
    }
    if (daily.length < 4) return null;

    final average =
        daily.values.fold<double>(0, (sum, value) => sum + value) /
        daily.length;
    if (average <= 0) return null;
    final candidate = daily.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final ratio = candidate.first.value / average;
    if (ratio < 2.5) return null;
    return MapEntry(candidate.first.key, ratio);
  }
}

class FinancialAssistantResponse {
  const FinancialAssistantResponse({
    required this.answer,
    this.suggestions = const [],
  });

  final String answer;
  final List<String> suggestions;
}

class FinancialAssistantService {
  FinancialAssistantService._();

  static const List<String> starterQuestions = [
    'Tháng này tôi tiêu gì nhiều nhất?',
    'Làm sao giảm chi tiêu?',
    'Dự đoán cuối tháng còn bao nhiêu?',
    'Tình hình ngân sách của tôi thế nào?',
  ];

  static FinancialAssistantResponse answer({
    required String question,
    required List<Transaction> currentMonth,
    required List<Transaction> previousMonth,
    required List<Category> categories,
    required List<Account> accounts,
    required List<Budget> budgets,
    required DateTime selectedMonth,
  }) {
    final normalized = _normalize(question);
    final expense = _sumByType(currentMonth, TransactionType.expense);
    final income = _sumByType(currentMonth, TransactionType.income);
    final saving = income - expense;

    if (normalized.isEmpty ||
        _containsAny(normalized, [
          'tong quan',
          'bao cao',
          'hom nay sao',
          'thang nay sao',
          'summary',
        ])) {
      return _overviewAnswer(
        currentMonth,
        previousMonth,
        categories,
        budgets,
        accounts,
        income,
        expense,
      );
    }

    if (_containsAny(normalized, ['xin chao', 'chao ban', 'hello'])) {
      return FinancialAssistantResponse(
        answer:
            'Chào bạn. Mình có thể phân tích thu chi tháng này, so sánh với tháng trước, tìm khoản bất thường, xem ngân sách và gợi ý cách tiết kiệm dựa trên dữ liệu trong máy.',
        suggestions: starterQuestions,
      );
    }

    if (_containsAny(normalized, [
      'tieu gi nhieu',
      'chi gi nhieu',
      'nhieu nhat',
      'top',
    ])) {
      return _topExpenseAnswer(currentMonth, categories, expense);
    }

    if (_containsAny(normalized, [
      'so sanh',
      'thang truoc',
      'tang hay giam',
      'xu huong',
      'trend',
    ])) {
      return _trendAnswer(currentMonth, previousMonth, categories);
    }

    if (_containsAny(normalized, [
      'bat thuong',
      'cao bat thuong',
      'dot bien',
      'anomaly',
    ])) {
      return _anomalyAnswer(currentMonth);
    }

    if (_containsAny(normalized, [
      'cuoi tuan',
      'thu bay',
      'chu nhat',
      'weekend',
    ])) {
      return _weekendAnswer(currentMonth, expense);
    }

    final categoryMatch = _categoryFromQuestion(normalized, categories);
    if (categoryMatch != null &&
        !_containsAny(normalized, ['ngan sach', 'han muc', 'budget'])) {
      return _categoryDetailAnswer(
        categoryMatch,
        currentMonth,
        previousMonth,
        expense,
      );
    }

    if (_containsAny(normalized, [
      'giam chi',
      'tiet kiem',
      'khuyen nghi',
      'lam sao',
    ])) {
      return _savingAdviceAnswer(
        currentMonth,
        previousMonth,
        categories,
        income,
        expense,
      );
    }

    if (_containsAny(normalized, [
      'cuoi thang',
      'du doan',
      'con bao nhieu',
      'forecast',
    ])) {
      final forecast = SmartFinanceService.buildForecast(
        currentMonth: currentMonth,
        selectedMonth: selectedMonth,
      );
      return FinancialAssistantResponse(
        answer:
            'Nếu giữ mức chi hiện tại, cuối tháng bạn dự kiến chi khoảng ${CurrencyFormatter.format(forecast.projectedExpense)}. '
            'Số tiền còn lại/tiết kiệm ước tính là ${CurrencyFormatter.format(forecast.projectedSaving)}. '
            'Trung bình mỗi ngày bạn đang chi ${CurrencyFormatter.format(forecast.averageDailyExpense)}.',
        suggestions: const [
          'Tháng này tôi tiêu gì nhiều nhất?',
          'Làm sao giảm chi tiêu?',
        ],
      );
    }

    if (_containsAny(normalized, ['ngan sach', 'han muc', 'budget'])) {
      return _budgetAnswer(budgets);
    }

    if (_containsAny(normalized, ['so du', 'vi', 'tai khoan', 'con tien'])) {
      final totalBalance = accounts.fold<double>(
        0,
        (sum, account) => sum + account.balance,
      );
      final defaultAccount = accounts
          .where((account) => account.isDefault)
          .firstOrNull;
      return FinancialAssistantResponse(
        answer:
            'Tổng số dư hiện tại của bạn là ${CurrencyFormatter.format(totalBalance)}. '
            '${defaultAccount == null ? '' : 'Ví mặc định là ${defaultAccount.name}, đang có ${CurrencyFormatter.format(defaultAccount.balance)}.'} '
            'Trong tháng này bạn thu ${CurrencyFormatter.format(income)}, chi ${CurrencyFormatter.format(expense)}, chênh lệch ${CurrencyFormatter.format(saving)}.',
        suggestions: const [
          'Dự đoán cuối tháng còn bao nhiêu?',
          'Tình hình ngân sách của tôi thế nào?',
        ],
      );
    }

    if (_containsAny(normalized, ['an uong', 'food', 'tra sua', 'ca phe'])) {
      final food = currentMonth
          .where(
            (t) =>
                t.type == TransactionType.expense && t.categoryId == 'cat_food',
          )
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      final pct = expense > 0 ? food / expense * 100 : 0;
      return FinancialAssistantResponse(
        answer:
            'Tháng này bạn đã chi ${CurrencyFormatter.format(food)} cho ăn uống, chiếm ${pct.toStringAsFixed(1)}% tổng chi tiêu. '
            '${pct >= 35 ? 'Mức này hơi cao, bạn có thể đặt hạn mức ăn uống theo tuần hoặc giảm các khoản nhỏ lặp lại.' : 'Mức này đang khá ổn so với tổng chi tiêu.'}',
        suggestions: const [
          'Làm sao giảm chi tiêu?',
          'Tháng này tôi tiêu gì nhiều nhất?',
        ],
      );
    }

    final insights = SmartFinanceService.buildInsights(
      currentMonth: currentMonth,
      previousMonth: previousMonth,
      categories: categories,
      selectedMonth: selectedMonth,
    );
    return FinancialAssistantResponse(
      answer:
          'Mình có thể trả lời dựa trên dữ liệu thu chi hiện tại. Gợi ý nhanh: ${insights.first.message}',
      suggestions: starterQuestions,
    );
  }

  static FinancialAssistantResponse _overviewAnswer(
    List<Transaction> currentMonth,
    List<Transaction> previousMonth,
    List<Category> categories,
    List<Budget> budgets,
    List<Account> accounts,
    double income,
    double expense,
  ) {
    final saving = income - expense;
    final previousExpense = _sumByType(previousMonth, TransactionType.expense);
    final totalBalance = accounts.fold<double>(
      0,
      (sum, account) => sum + account.balance,
    );
    final activeBudgets = budgets.where((budget) => budget.isActive).toList();
    final exceededBudgets = activeBudgets
        .where((budget) => budget.isExceeded)
        .length;
    final top = _expenseTotals(currentMonth).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topText = top.isEmpty
        ? 'chưa có nhóm chi nổi bật'
        : '${_categoryName(top.first.key, categories)} đang cao nhất với ${CurrencyFormatter.format(top.first.value)}';
    final trendText = previousExpense <= 0
        ? 'Chưa đủ dữ liệu tháng trước để so sánh.'
        : 'Chi tiêu ${expense >= previousExpense ? 'tăng' : 'giảm'} ${(((expense - previousExpense).abs() / previousExpense) * 100).toStringAsFixed(1)}% so với tháng trước.';

    return FinancialAssistantResponse(
      answer:
          'Tổng quan tháng này: thu ${CurrencyFormatter.format(income)}, chi ${CurrencyFormatter.format(expense)}, chênh lệch ${CurrencyFormatter.format(saving)}. '
          'Số dư ví/tài khoản hiện là ${CurrencyFormatter.format(totalBalance)}. $topText. $trendText '
          '${exceededBudgets > 0
              ? 'Có $exceededBudgets ngân sách đã vượt hạn mức, nên xử lý trước.'
              : activeBudgets.isEmpty
              ? 'Bạn chưa tạo ngân sách, nên thêm hạn mức cho các nhóm chi chính.'
              : 'Ngân sách hiện chưa có nhóm vượt hạn mức.'}',
      suggestions: const [
        'Khoản nào bất thường?',
        'So với tháng trước thế nào?',
        'Làm sao giảm chi tiêu?',
      ],
    );
  }

  static FinancialAssistantResponse _trendAnswer(
    List<Transaction> currentMonth,
    List<Transaction> previousMonth,
    List<Category> categories,
  ) {
    final currentExpense = _sumByType(currentMonth, TransactionType.expense);
    final previousExpense = _sumByType(previousMonth, TransactionType.expense);
    final currentIncome = _sumByType(currentMonth, TransactionType.income);
    final previousIncome = _sumByType(previousMonth, TransactionType.income);

    if (previousExpense <= 0 && previousIncome <= 0) {
      return const FinancialAssistantResponse(
        answer:
            'Mình chưa có đủ dữ liệu tháng trước để so sánh. Bạn có thể nhập thêm giao dịch tháng trước hoặc dùng phần tổng quan tháng này trước.',
        suggestions: [
          'Tổng quan tháng này',
          'Tháng này tôi tiêu gì nhiều nhất?',
        ],
      );
    }

    final expenseChange = previousExpense > 0
        ? ((currentExpense - previousExpense) / previousExpense) * 100
        : 0.0;
    final incomeChange = previousIncome > 0
        ? ((currentIncome - previousIncome) / previousIncome) * 100
        : 0.0;
    final currentTop = _expenseTotals(currentMonth);
    final previousTop = _expenseTotals(previousMonth);
    final deltas = <String, double>{};
    for (final id in {...currentTop.keys, ...previousTop.keys}) {
      deltas[id] = (currentTop[id] ?? 0) - (previousTop[id] ?? 0);
    }
    final biggestChange = deltas.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final driver = biggestChange.isEmpty
        ? ''
        : 'Thay đổi đáng chú ý nhất là ${_categoryName(biggestChange.first.key, categories)} ${biggestChange.first.value >= 0 ? 'tăng' : 'giảm'} ${CurrencyFormatter.format(biggestChange.first.value.abs())}.';

    return FinancialAssistantResponse(
      answer:
          'So với tháng trước: chi tiêu ${expenseChange >= 0 ? 'tăng' : 'giảm'} ${expenseChange.abs().toStringAsFixed(1)}%, thu nhập ${incomeChange >= 0 ? 'tăng' : 'giảm'} ${incomeChange.abs().toStringAsFixed(1)}%. $driver',
      suggestions: const [
        'Khoản nào bất thường?',
        'Dự đoán cuối tháng còn bao nhiêu?',
      ],
    );
  }

  static FinancialAssistantResponse _anomalyAnswer(
    List<Transaction> transactions,
  ) {
    final daily = <DateTime, double>{};
    for (final transaction in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      daily[day] = (daily[day] ?? 0) + transaction.amount;
    }
    if (daily.length < 4) {
      return const FinancialAssistantResponse(
        answer:
            'Chưa đủ số ngày chi tiêu để phát hiện bất thường. Khi có từ 4 ngày ghi chép trở lên, mình sẽ so ngày cao nhất với mức trung bình.',
        suggestions: ['Tổng quan tháng này'],
      );
    }
    final average =
        daily.values.fold<double>(0, (sum, value) => sum + value) /
        daily.length;
    final sorted = daily.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final ratio = average > 0 ? top.value / average : 0;

    return FinancialAssistantResponse(
      answer: ratio >= 2.5
          ? 'Có dấu hiệu bất thường: ngày ${DateFormatter.formatDate(top.key)} bạn chi ${CurrencyFormatter.format(top.value)}, cao gấp ${ratio.toStringAsFixed(1)} lần mức trung bình ngày.'
          : 'Chưa thấy khoản chi ngày nào bất thường rõ. Ngày cao nhất là ${DateFormatter.formatDate(top.key)} với ${CurrencyFormatter.format(top.value)}, mức này vẫn chưa vượt xa trung bình.',
      suggestions: const [
        'So với tháng trước thế nào?',
        'Làm sao giảm chi tiêu?',
      ],
    );
  }

  static FinancialAssistantResponse _weekendAnswer(
    List<Transaction> transactions,
    double totalExpense,
  ) {
    final weekendExpense = transactions
        .where((transaction) {
          final day = transaction.date.weekday;
          return transaction.type == TransactionType.expense &&
              (day == DateTime.saturday || day == DateTime.sunday);
        })
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final pct = totalExpense > 0 ? weekendExpense / totalExpense * 100 : 0;

    return FinancialAssistantResponse(
      answer:
          'Cuối tuần tháng này bạn chi ${CurrencyFormatter.format(weekendExpense)}, chiếm ${pct.toStringAsFixed(1)}% tổng chi tiêu. '
          '${pct >= 45 ? 'Tỷ lệ này khá cao, nên đặt hạn mức riêng cho cuối tuần hoặc kiểm tra các khoản ăn uống/giải trí.' : 'Tỷ lệ này đang ổn, chưa phải điểm nóng lớn.'}',
      suggestions: const [
        'Tháng này tôi tiêu gì nhiều nhất?',
        'Khoản nào bất thường?',
      ],
    );
  }

  static FinancialAssistantResponse _categoryDetailAnswer(
    Category category,
    List<Transaction> currentMonth,
    List<Transaction> previousMonth,
    double totalExpense,
  ) {
    final current = _transactionTotalByCategory(currentMonth, category.id);
    final previous = _transactionTotalByCategory(previousMonth, category.id);
    final pct = totalExpense > 0 ? current / totalExpense * 100 : 0;
    final trend = previous > 0
        ? 'So với tháng trước, nhóm này ${current >= previous ? 'tăng' : 'giảm'} ${(((current - previous).abs() / previous) * 100).toStringAsFixed(1)}%.'
        : 'Chưa có dữ liệu tháng trước cho nhóm này.';

    return FinancialAssistantResponse(
      answer:
          '${category.name}: tháng này bạn đã chi ${CurrencyFormatter.format(current)}, chiếm ${pct.toStringAsFixed(1)}% tổng chi tiêu. $trend '
          '${pct >= 30 ? 'Đây là nhóm đang chiếm tỷ trọng cao, nên đặt hạn mức tuần hoặc tách các giao dịch nhỏ để kiểm soát.' : 'Nhóm này chưa chiếm tỷ trọng quá lớn.'}',
      suggestions: const [
        'Làm sao giảm chi tiêu?',
        'So với tháng trước thế nào?',
      ],
    );
  }

  static FinancialAssistantResponse _topExpenseAnswer(
    List<Transaction> transactions,
    List<Category> categories,
    double totalExpense,
  ) {
    final totals = <String, double>{};
    for (final transaction in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      totals[transaction.categoryId] =
          (totals[transaction.categoryId] ?? 0) + transaction.amount;
    }
    if (totals.isEmpty) {
      return const FinancialAssistantResponse(
        answer: 'Tháng này chưa có dữ liệu chi tiêu để phân tích.',
        suggestions: ['Tôi nên ghi chép như thế nào?'],
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLines = sorted
        .take(3)
        .map((entry) {
          final categoryName =
              categories
                  .where((category) => category.id == entry.key)
                  .firstOrNull
                  ?.name ??
              'Khác';
          final pct = totalExpense > 0 ? entry.value / totalExpense * 100 : 0;
          return '$categoryName: ${CurrencyFormatter.format(entry.value)} (${pct.toStringAsFixed(1)}%)';
        })
        .join('\n');

    return FinancialAssistantResponse(
      answer: 'Các khoản chi nhiều nhất tháng này là:\n$topLines',
      suggestions: const [
        'Làm sao giảm chi tiêu?',
        'Tình hình ngân sách của tôi thế nào?',
      ],
    );
  }

  static FinancialAssistantResponse _savingAdviceAnswer(
    List<Transaction> currentMonth,
    List<Transaction> previousMonth,
    List<Category> categories,
    double income,
    double expense,
  ) {
    final totals = <String, double>{};
    for (final transaction in currentMonth.where(
      (t) => t.type == TransactionType.expense,
    )) {
      totals[transaction.categoryId] =
          (totals[transaction.categoryId] ?? 0) + transaction.amount;
    }
    if (totals.isEmpty) {
      return const FinancialAssistantResponse(
        answer:
            'Bạn chưa có nhiều dữ liệu chi tiêu. Hãy ghi giao dịch đều vài ngày, sau đó mình sẽ đề xuất giảm chi cụ thể hơn.',
        suggestions: ['Tháng này tôi tiêu gì nhiều nhất?'],
      );
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final topName =
        categories
            .where((category) => category.id == top.key)
            .firstOrNull
            ?.name ??
        'danh mục lớn nhất';
    final targetSaving = top.value * 0.15;
    final savingRate = income > 0 ? (income - expense) / income * 100 : 0;
    final previousExpense = _sumByType(previousMonth, TransactionType.expense);
    final trend = previousExpense > 0
        ? 'So với tháng trước, chi tiêu của bạn ${expense > previousExpense ? 'đang tăng' : 'đang giảm'}. '
        : '';

    return FinancialAssistantResponse(
      answer:
          '${trend}Khoản nên tối ưu đầu tiên là $topName vì đang chi ${CurrencyFormatter.format(top.value)}. '
          'Nếu giảm 15% nhóm này, bạn tiết kiệm thêm khoảng ${CurrencyFormatter.format(targetSaving)}. '
          'Tỷ lệ tiết kiệm hiện tại là ${savingRate.toStringAsFixed(1)}%; mục tiêu tốt nên là từ 20% trở lên.',
      suggestions: const [
        'Dự đoán cuối tháng còn bao nhiêu?',
        'Tháng này tôi tiêu gì nhiều nhất?',
      ],
    );
  }

  static FinancialAssistantResponse _budgetAnswer(List<Budget> budgets) {
    final active = budgets.where((budget) => budget.isActive).toList();
    if (active.isEmpty) {
      return const FinancialAssistantResponse(
        answer:
            'Bạn chưa có ngân sách đang hoạt động. Nên tạo ngân sách cho Ăn uống, Di chuyển và Giải trí trước vì đây thường là nhóm dễ vượt nhất.',
        suggestions: ['Làm sao giảm chi tiêu?'],
      );
    }
    final limit = active.fold<double>(0, (sum, budget) => sum + budget.limit);
    final spent = active.fold<double>(0, (sum, budget) => sum + budget.spent);
    final exceeded = active.where((budget) => budget.isExceeded).length;
    final warning = active.where((budget) => budget.isWarning).length;
    final pct = limit > 0 ? spent / limit * 100 : 0;

    return FinancialAssistantResponse(
      answer:
          'Bạn đã dùng ${pct.toStringAsFixed(1)}% tổng ngân sách (${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(limit)}). '
          'Có $exceeded ngân sách đã vượt hạn mức và $warning ngân sách gần chạm hạn mức.',
      suggestions: const [
        'Làm sao giảm chi tiêu?',
        'Dự đoán cuối tháng còn bao nhiêu?',
      ],
    );
  }

  static Map<String, double> _expenseTotals(List<Transaction> transactions) {
    final totals = <String, double>{};
    for (final transaction in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      totals[transaction.categoryId] =
          (totals[transaction.categoryId] ?? 0) + transaction.amount;
    }
    return totals;
  }

  static double _transactionTotalByCategory(
    List<Transaction> transactions,
    String categoryId,
  ) {
    return transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense &&
              transaction.categoryId == categoryId,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  static String _categoryName(String categoryId, List<Category> categories) {
    return categories
            .where((category) => category.id == categoryId)
            .firstOrNull
            ?.name ??
        'Khác';
  }

  static Category? _categoryFromQuestion(
    String normalizedQuestion,
    List<Category> categories,
  ) {
    for (final category in categories.where((category) => !category.isIncome)) {
      final normalizedName = _normalize(category.name);
      if (normalizedName.isNotEmpty &&
          normalizedQuestion.contains(normalizedName)) {
        return category;
      }
    }

    const aliases = {
      'cat_food': [
        'an uong',
        'do an',
        'tra sua',
        'ca phe',
        'com',
        'pho',
        'grabfood',
        'shopeefood',
      ],
      'cat_transport': [
        'di chuyen',
        'xang',
        'grab',
        'xanhsm',
        'xanh sm',
        'be',
        'taxi',
        'metro',
      ],
      'cat_shopping': ['mua sam', 'shopee', 'lazada', 'tiki', 'quan ao'],
      'cat_entertainment': [
        'giai tri',
        'game',
        'phim',
        'netflix',
        'valorant',
        'spotify',
      ],
      'cat_health': [
        'suc khoe',
        'thuoc',
        'benh vien',
        'kham benh',
        'long chau',
        'pharmacity',
      ],
      'cat_education': [
        'hoc tap',
        'hoc phi',
        'sach',
        'khoa hoc',
        'ielts',
        'toeic',
      ],
      'cat_bills': [
        'hoa don',
        'dien nuoc',
        'wifi',
        'internet',
        'viettel',
        'fpt',
      ],
      'cat_housing': ['nha o', 'tien nha', 'thue nha', 'phong tro', 'chung cu'],
    };

    for (final entry in aliases.entries) {
      if (_containsAny(normalizedQuestion, entry.value)) {
        return categories
            .where((category) => category.id == entry.key)
            .firstOrNull;
      }
    }
    return null;
  }

  static double _sumByType(
    List<Transaction> transactions,
    TransactionType type,
  ) {
    return transactions
        .where((transaction) => transaction.type == type)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  static String _normalize(String value) {
    return _normalizeVietnameseText(value);
    /*
    const source =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const target =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = value.toLowerCase();
    for (var i = 0; i < source.length; i++) {
      result = result.replaceAll(source[i], target[i]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
    */
  }
}
