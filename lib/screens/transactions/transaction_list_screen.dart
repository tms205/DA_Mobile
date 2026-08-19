import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/cards/transaction_list_tile.dart';
import '../../widgets/common/empty_state.dart';
import 'add_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  TransactionType? _activeFilter;
  int _selectedMonth = DateTime.now().month;
  final int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<TransactionProvider>().loadTransactionsForMonth(
      _selectedYear,
      _selectedMonth,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navTransactions),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTypeFilter(),
          Expanded(child: _buildTransactionList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ).then((_) => _loadData()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Row(
            children: [
              _buildSummaryChip(
                'Thu',
                provider.totalIncome,
                AppColors.accentGold,
              ),
              const SizedBox(width: 12),
              _buildSummaryChip(
                'Chi',
                provider.totalExpense,
                Colors.redAccent.shade100,
              ),
              const Spacer(),
              _buildMonthSelector(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryChip(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          CurrencyFormatter.compact(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: _showMonthPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              '${DateFormatter.monthName(_selectedMonth)} $_selectedYear',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return Container(
      color: containerBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        enableSuggestions: false,
        autocorrect: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        onChanged: (_) => _scheduleSearch(),
        decoration: InputDecoration(
          hintText: AppStrings.searchTransactions,
          prefixIcon: Icon(Icons.search, color: hintColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<TransactionProvider>().setSearchQuery('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final primarySurfaceColor = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final filters = [
      {'label': 'Tất cả', 'type': null},
      {'label': 'Thu nhập', 'type': TransactionType.income},
      {'label': 'Chi tiêu', 'type': TransactionType.expense},
    ];

    return Container(
      color: containerBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f['type'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label'] as String),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _activeFilter = f['type'] as TransactionType?);
                context.read<TransactionProvider>().setFilterType(
                  f['type'] as TransactionType?,
                );
              },
              selectedColor: primarySurfaceColor,
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : textSecColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final grouped = provider.transactionsByDate;
        if (grouped.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long,
            message: AppStrings.noTransactions,
          );
        }
        final sortedDates = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sortedDates.length,
          itemBuilder: (context, i) {
            final date = sortedDates[i];
            final dayTxs = grouped[date]!;
            final dayTotal = dayTxs.fold<double>(
              0,
              (sum, t) => t.type == TransactionType.income
                  ? sum + t.amount
                  : t.type == TransactionType.expense
                  ? sum - t.amount
                  : sum,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.formatRelative(date),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.txtSec(isDark),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(dayTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: dayTotal >= 0
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                ...dayTxs.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionListTile(
                      transaction: t,
                      category: provider.getCategoryById(t.categoryId),
                      account: provider.getAccountById(t.accountId),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddTransactionScreen(existingTransaction: t),
                        ),
                      ).then((_) => _loadData()),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textPriColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bộ lọc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPriColor),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<TransactionProvider>().clearFilters();
                  _searchController.clear();
                  setState(() => _activeFilter = null);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Xóa bộ lọc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    final composing = _searchController.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;

    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      context.read<TransactionProvider>().setSearchQuery(
        _searchController.text,
      );
    });
  }

  void _showMonthPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textPriColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chọn tháng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPriColor),
              ),
            ),
            SizedBox(
              height: 300,
              child: GridView.count(
                crossAxisCount: 4,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: List.generate(12, (i) {
                  final month = i + 1;
                  final isSelected = month == _selectedMonth;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMonth = month);
                      Navigator.pop(ctx);
                      _loadData();
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : AppColors.sfVariant(isDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'T$month',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : textPriColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
