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
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome ? AppColors.income
        : isTransfer ? AppColors.info : AppColors.expense;
    final amountPrefix = isIncome ? '+' : isTransfer ? '↔' : '-';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (category?.colorValue ?? amountColor).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTransfer ? Icons.swap_horiz : (category?.iconData ?? Icons.receipt),
              color: category?.colorValue ?? amountColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                category?.name ?? (isTransfer ? 'Chuyển khoản' : 'Giao dịch'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(children: [
                if (transaction.note.isNotEmpty) ...[
                  Expanded(
                    child: Text(transaction.note,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ] else ...[
                  Text(
                    account?.name ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
                const SizedBox(width: 8),
                if (transaction.isRecurring)
                  const Icon(Icons.repeat, size: 12, color: AppColors.textHint),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '$amountPrefix${CurrencyFormatter.compact(transaction.amount)}',
              style: TextStyle(
                color: amountColor, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormatter.formatRelative(transaction.date),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ]),
        ]),
      ),
    );
  }
}
