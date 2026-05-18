import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import 'add_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final budgetProvider = context.read<BudgetProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    await Future.wait([
      budgetProvider.loadBudgets(),
      categoryProvider.loadCategories(),
    ]);
    await budgetProvider.refreshBudgetSpending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.budget)),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: Consumer<BudgetProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryCard(provider),
                        const SizedBox(height: 20),
                        if (provider.exceededBudgets.isNotEmpty) ...[
                          _buildAlertSection(
                            provider.exceededBudgets,
                            isExceeded: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (provider.warningBudgets.isNotEmpty) ...[
                          _buildAlertSection(
                            provider.warningBudgets,
                            isExceeded: false,
                          ),
                          const SizedBox(height: 16),
                        ],
                        SectionHeader(title: 'Tất cả ngân sách'),
                        const SizedBox(height: 12),
                        if (provider.budgets.isEmpty)
                          const EmptyState(
                            icon: Icons.account_balance_wallet,
                            message: AppStrings.noBudgets,
                          )
                        else
                          ...provider.budgets.map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildBudgetCard(b, provider),
                            ),
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
        ).then((_) => _loadData()),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm ngân sách',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BudgetProvider provider) {
    final total = provider.totalBudgetLimit;
    final spent = provider.totalBudgetSpent;
    final remaining = total - spent;
    final pct = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan ngân sách tháng này',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _budgetStat('Hạn mức', total, Colors.white)),
              const SizedBox(width: 10),
              Expanded(
                child: _budgetStat('Đã chi', spent, AppColors.accentGold),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _budgetStat(
                  'Còn lại',
                  remaining,
                  remaining < 0 ? Colors.redAccent : Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(
                pct > 0.9 ? Colors.redAccent : Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(pct * 100).toStringAsFixed(1)}% đã sử dụng',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _budgetStat(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.compact(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAlertSection(List<Budget> budgets, {required bool isExceeded}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExceeded
            ? AppColors.expense.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExceeded
              ? AppColors.expense.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExceeded ? Icons.error_outline : Icons.warning_amber,
            color: isExceeded ? AppColors.expense : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isExceeded
                  ? '${budgets.length} ngân sách đã vượt hạn mức!'
                  : '${budgets.length} ngân sách gần đến hạn mức!',
              style: TextStyle(
                color: isExceeded ? AppColors.expense : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget, BudgetProvider provider) {
    final category = provider.getCategoryById(budget.categoryId);
    final pct = budget.percentage;

    Color progressColor;
    if (budget.isExceeded) {
      progressColor = AppColors.expense;
    } else if (budget.isWarning) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.income;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddBudgetScreen(existingBudget: budget),
        ),
      ).then((_) => _loadData()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (category?.colorValue ?? AppColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category?.iconData ?? Icons.category,
                    color: category?.colorValue ?? AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Danh mục',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        budget.periodName,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (budget.isExceeded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Vượt hạn!',
                      style: TextStyle(
                        color: AppColors.expense,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    CurrencyFormatter.format(budget.spent),
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '/ ${CurrencyFormatter.format(budget.limit)}',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: progressColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Còn lại: ${CurrencyFormatter.format(budget.remaining.clamp(0, double.infinity))}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
