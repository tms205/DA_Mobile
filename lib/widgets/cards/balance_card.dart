import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isObscured = false;
  static const _obscureKey = 'settings_balance_obscured';

  @override
  void initState() {
    super.initState();
    _loadObscureState();
  }

  Future<void> _loadObscureState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isObscured = prefs.getBool(_obscureKey) ?? false;
    });
  }

  Future<void> _toggleObscure() async {
    setState(() {
      _isObscured = !_isObscured;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_obscureKey, _isObscured);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.cardGradientDark : AppColors.cardGradient;

    return Consumer2<AccountProvider, TransactionProvider>(
      builder: (context, accProvider, txProvider, _) {
        final totalBalance = accProvider.totalBalance;
        final income = txProvider.totalIncome;
        final expense = txProvider.totalExpense;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.dynamicElevatedShadow(isDark),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TỔNG SỐ DƯ KHẢ DỤNG',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleObscure,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _isObscured ? '••••••' : CurrencyFormatter.format(totalBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildStatRow(
                      Icons.arrow_upward_rounded,
                      'Thu nhập',
                      income,
                      AppColors.accentGold,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: Colors.white.withValues(alpha: 0.15),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildStatRow(
                      Icons.arrow_downward_rounded,
                      'Chi tiêu',
                      expense,
                      Colors.redAccent.shade100,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String label, double amount, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                _isObscured ? '••••••' : CurrencyFormatter.compact(amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
