import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/common/section_header.dart';

class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final textTitleStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );

    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final activeBudgets = provider.activeBudgets.toList()
          ..sort((a, b) {
            final aPriority = a.isExceeded
                ? 0
                : a.isWarning
                ? 1
                : 2;
            final bPriority = b.isExceeded
                ? 0
                : b.isWarning
                ? 1
                : 2;
            final priorityCompare = aPriority.compareTo(bPriority);
            if (priorityCompare != 0) return priorityCompare;
            return b.updatedAt.compareTo(a.updatedAt);
          });
        final budgets = activeBudgets.take(3).toList();
        final totalLimit = activeBudgets.fold<double>(
          0,
          (sum, budget) => sum + budget.limit,
        );
        final totalSpent = activeBudgets.fold<double>(
          0,
          (sum, budget) => sum + budget.spent,
        );
        final totalRemaining = totalLimit - totalSpent;
        final totalProgress = totalLimit > 0
            ? (totalSpent / totalLimit).clamp(0.0, 1.0)
            : 0.0;
        return Column(
          children: [
            SectionHeader(title: AppStrings.budgetOverview),
            const SizedBox(height: 12),
            if (budgets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.dynamicCardShadow(isDark),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'Chưa có ngân sách nào.\nThêm ngân sách để theo dõi chi tiêu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: hintColor, height: 1.5, fontSize: 13),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.dynamicCardShadow(isDark),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children:
                      budgets
                          .map((budget) {
                            final isFirst = budget == budgets.first;
                            final cat = provider.getCategoryById(
                              budget.categoryId,
                            );
                            final pct = budget.percentage;
                            final progressColor = budget.isExceeded
                                ? AppColors.expense
                                : budget.isWarning
                                ? AppColors.warning
                                : AppColors.income;
                            return Padding(
                              padding: EdgeInsets.only(
                                top: isFirst ? 14 : 0,
                                bottom: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        cat?.iconData ?? Icons.category_rounded,
                                        size: 16,
                                        color:
                                            cat?.colorValue ??
                                            AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cat?.name ?? 'Danh mục',
                                          style: textTitleStyle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '${CurrencyFormatter.compact(budget.spent)} / ${CurrencyFormatter.compact(budget.limit)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hintColor,
                                            fontWeight: FontWeight.w500,
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
                                      minHeight: 6,
                                      backgroundColor: progressColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      valueColor: AlwaysStoppedAnimation(
                                        progressColor,
                                      ),
                                    ),
                                  ),
                                  if (budget.isExceeded)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        AppStrings.budgetExceeded,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.expense,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (budget.isWarning)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        AppStrings.budgetWarning,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          })
                          .cast<Widget>()
                          .toList()
                        ..insert(
                          0,
                          _BudgetSummary(
                            limit: totalLimit,
                            spent: totalSpent,
                            remaining: totalRemaining,
                            progress: totalProgress,
                          ),
                        ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.progress,
  });

  final double limit;
  final double spent;
  final double remaining;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = progress >= 1
        ? AppColors.expense
        : progress >= 0.8
        ? AppColors.warning
        : AppColors.income;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _summaryItem(context, 'Hạn mức', limit, isDark ? AppColors.accent : AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _summaryItem(context, 'Đã chi', spent, AppColors.expense)),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryItem(
                context,
                'Còn lại',
                remaining,
                remaining < 0 ? AppColors.expense : AppColors.income,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: progressColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% đã sử dụng',
          style: TextStyle(fontSize: 11, color: hintColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Divider(height: 18, color: dividerColor),
      ],
    );
  }

  Widget _summaryItem(BuildContext context, String label, double amount, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: hintColor, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.compact(amount),
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
