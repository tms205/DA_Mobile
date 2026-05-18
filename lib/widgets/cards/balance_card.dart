import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountProvider, TransactionProvider>(
      builder: (context, accProvider, txProvider, _) {
        final totalBalance = accProvider.totalBalance;
        final income = txProvider.totalIncome;
        final expense = txProvider.totalExpense;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng số dư', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(totalBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildStatRow(
                  Icons.arrow_upward_rounded, 'Thu nhập',
                  income, AppColors.accentGold,
                )),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(child: _buildStatRow(
                  Icons.arrow_downward_rounded, 'Chi tiêu',
                  expense, Colors.redAccent.shade100,
                  leftPadding: 16,
                )),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String label, double amount, Color color,
      {double leftPadding = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(CurrencyFormatter.compact(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ]),
    );
  }
}
