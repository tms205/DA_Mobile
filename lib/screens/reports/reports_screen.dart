import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/smart_finance_service.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../assistant/financial_assistant_screen.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/common/section_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<Transaction> _currentMonthTransactions = [];
  List<Transaction> _previousMonthTransactions = [];
  List<Transaction> _yearTransactions = [];
  bool _isLoadingSmartData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoadingSmartData = true);
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final previousMonth = DateTime(_selectedYear, _selectedMonth - 1, 1);
    await Future.wait([
      transactionProvider.loadTransactionsForMonth(
        _selectedYear,
        _selectedMonth,
      ),
      categoryProvider.loadCategories(),
    ]);
    final results = await Future.wait([
      transactionProvider.fetchTransactionsForMonth(
        _selectedYear,
        _selectedMonth,
      ),
      transactionProvider.fetchTransactionsForMonth(
        previousMonth.year,
        previousMonth.month,
      ),
      transactionProvider.fetchTransactionsForYear(_selectedYear),
    ]);
    if (!mounted) return;
    setState(() {
      _currentMonthTransactions = results[0];
      _previousMonthTransactions = results[1];
      _yearTransactions = results[2];
      _isLoadingSmartData = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FinancialAssistantScreen(),
              ),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI Financial Assistant',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Danh mục'),
            Tab(text: 'Xu hướng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildCategoryTab(), _buildTrendTab()],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, provider, categoryProvider, _) {
        final monthTransactions = _currentMonthTransactions.isNotEmpty
            ? _currentMonthTransactions
            : provider.allTransactions;
        final income = _sumByType(monthTransactions, TransactionType.income);
        final expense = _sumByType(monthTransactions, TransactionType.expense);
        final savings = income - expense;
        final savingsRate = income > 0 ? (savings / income * 100) : 0.0;
        final selectedDate = DateTime(_selectedYear, _selectedMonth, 1);
        final insights = SmartFinanceService.buildInsights(
          currentMonth: monthTransactions,
          previousMonth: _previousMonthTransactions,
          categories: categoryProvider.categories,
          selectedMonth: selectedDate,
        );
        final forecast = SmartFinanceService.buildForecast(
          currentMonth: monthTransactions,
          selectedMonth: selectedDate,
        );
        final badges = SmartFinanceService.buildBadges(monthTransactions);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMonthSelector(),
            if (_isLoadingSmartData) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
              ),
            ],
            const SizedBox(height: 16),
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Thu nhập',
                    income,
                    AppColors.income,
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Chi tiêu',
                    expense,
                    AppColors.expense,
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tiết kiệm',
                    savings,
                    savings >= 0 ? AppColors.info : AppColors.expense,
                    Icons.savings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildRateCard(savingsRate)),
              ],
            ),
            const SizedBox(height: 20),
            // Income vs Expense Bar Chart
            _buildIncomeExpenseChart(income, expense),
            const SizedBox(height: 20),
            _buildSmartInsightsCard(insights),
            const SizedBox(height: 16),
            _buildForecastCard(forecast),
            const SizedBox(height: 16),
            _buildBadgesCard(badges),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildCategoryTab() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final expByCategory = provider.expenseByCategory;
        if (expByCategory.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu chi tiêu'));
        }

        // Top categories
        final sorted = expByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.take(5).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 16),
            Container(
              height: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
              ),
              child: PieChartWidget(
                dataMap: {
                  for (final e in top)
                    (provider.getCategoryById(e.key)?.name ?? 'Khác'): e.value,
                },
                colorList: AppColors.chartPalette,
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: AppStrings.topExpenses),
            const SizedBox(height: 12),
            ...sorted.take(8).map((entry) {
              final cat = provider.getCategoryById(entry.key);
              final total = expByCategory.values.fold(0.0, (a, b) => a + b);
              final pct = total > 0 ? (entry.value / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (cat?.colorValue ?? AppColors.primary)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          cat?.iconData ?? Icons.category,
                          color: cat?.colorValue ?? AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat?.name ?? 'Khác',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 6,
                                backgroundColor: AppColors.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation(
                                  cat?.colorValue ?? AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.compact(entry.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.expense,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildTrendTab() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final yearTransactions = _yearTransactions.isNotEmpty
            ? _yearTransactions
            : provider.allTransactions;
        final expenses = _monthlyTotals(
          yearTransactions,
          TransactionType.expense,
        );
        final incomes = _monthlyTotals(
          yearTransactions,
          TransactionType.income,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildYearSelector(),
            const SizedBox(height: 16),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
              ),
              child: BarChartWidget(expenses: expenses, incomes: incomes),
            ),
            const SizedBox(height: 16),
            // Monthly summary table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Tháng',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Thu nhập',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.income,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Chi tiêu',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ...List.generate(
                    12,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormatter.monthName(i + 1),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.compact(incomes[i]),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.income,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.compact(expenses[i]),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.expense,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildSmartInsightsCard(List<SmartFinanceInsight> insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Phân tích thông minh',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: insight.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(insight.icon, color: insight.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          insight.message,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildForecastCard(ForecastResult forecast) {
    final savingColor = forecast.projectedSaving >= 0
        ? AppColors.income
        : AppColors.expense;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Text(
                'Dự đoán cuối tháng',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _forecastMetric(
                  'Chi/ngày',
                  CurrencyFormatter.compact(forecast.averageDailyExpense),
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _forecastMetric(
                  'Dự kiến chi',
                  CurrencyFormatter.compact(forecast.projectedExpense),
                  AppColors.expense,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _forecastMetric(
                  'Còn lại',
                  CurrencyFormatter.compact(forecast.projectedSaving),
                  savingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            forecast.daysRemaining > 0
                ? 'Còn ${forecast.daysRemaining} ngày. Nếu giữ nhịp hiện tại, app ước tính số tiền cuối tháng như trên.'
                : 'Đây là tổng kết dựa trên dữ liệu của tháng đã chọn.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesCard(List<SmartBadge> badges) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppColors.accentGold,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Huy hiệu tài chính',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...badges.map((badge) {
            final color = badge.unlocked ? badge.color : AppColors.textHint;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    badge.unlocked ? badge.icon : Icons.lock_outline_rounded,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.title,
                          style: TextStyle(
                            color: badge.unlocked
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          badge.description,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    badge.unlocked ? 'Đạt' : 'Chưa',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  double _sumByType(List<Transaction> transactions, TransactionType type) {
    return transactions
        .where((transaction) => transaction.type == type)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  List<double> _monthlyTotals(
    List<Transaction> transactions,
    TransactionType type,
  ) {
    final result = List<double>.filled(12, 0);
    for (final transaction in transactions.where((t) => t.type == type)) {
      if (transaction.date.year == _selectedYear) {
        result[transaction.date.month - 1] += transaction.amount;
      }
    }
    return result;
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              if (_selectedMonth == 1) {
                _selectedMonth = 12;
                _selectedYear--;
              } else {
                _selectedMonth--;
              }
            });
            _loadData();
          },
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
        ),
        Expanded(
          child: Text(
            '${DateFormatter.monthName(_selectedMonth)} $_selectedYear',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              if (_selectedMonth == 12) {
                _selectedMonth = 1;
                _selectedYear++;
              } else {
                _selectedMonth++;
              }
            });
            _loadData();
          },
          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() => _selectedYear--);
            _loadData();
          },
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
        ),
        Expanded(
          child: Text(
            'Năm $_selectedYear',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() => _selectedYear++);
            _loadData();
          },
          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.compact(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(double rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.percent, color: AppColors.info, size: 18),
              SizedBox(width: 6),
              Text(
                'Tỷ lệ tiết kiệm',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: rate >= 20
                  ? AppColors.income
                  : rate >= 0
                  ? AppColors.warning
                  : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseChart(double income, double expense) {
    final maxVal = [income, expense].reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thu nhập vs Chi tiêu',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 20),
          if (maxVal == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: AppColors.income,
                          width: 40,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: expense,
                          color: AppColors.expense,
                          width: 40,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          v == 0 ? 'Thu nhập' : 'Chi tiêu',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
