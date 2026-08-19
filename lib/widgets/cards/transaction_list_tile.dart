import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final Account? account;
  final VoidCallback? onTap;

  const TransactionListTile({
    super.key,
    required this.transaction,
    this.category,
    this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    
    final amountColor = isIncome 
        ? AppColors.income
        : isTransfer ? (isDark ? AppColors.accent : AppColors.primary) : AppColors.expense;
    final amountPrefix = isIncome ? '+' : isTransfer ? '↔' : '-';

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textTitleStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );
    final textSubtitleStyle = TextStyle(
      fontSize: 12,
      color: isDark ? AppColors.textHintDark : AppColors.textHint,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.dynamicCardShadow(isDark),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (category?.colorValue ?? amountColor).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTransfer ? Icons.swap_horiz : (category?.iconData ?? Icons.receipt_long_rounded),
                color: category?.colorValue ?? amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? (isTransfer ? 'Chuyển khoản' : 'Giao dịch'),
                    style: textTitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (transaction.note.isNotEmpty) ...[
                        Expanded(
                          child: Text(
                            transaction.note,
                            style: textSubtitleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        Text(
                          account?.name ?? '',
                          style: textSubtitleStyle,
                        ),
                      ],
                      if (transaction.isRecurring) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.repeat_rounded,
                          size: 13,
                          color: isDark ? AppColors.textHintDark : AppColors.textHint,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${CurrencyFormatter.compact(transaction.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatRelative(transaction.date),
                  style: textSubtitleStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
