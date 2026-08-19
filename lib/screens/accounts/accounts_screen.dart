import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AccountProvider>().loadAccounts());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.accounts)),
      body: Consumer<AccountProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTotalCard(provider),
              const SizedBox(height: 20),
              _buildQuickStats(provider),
              const SizedBox(height: 20),
              if (provider.accounts.isEmpty)
                EmptyState(
                  icon: Icons.account_balance_wallet,
                  message: AppStrings.noAccounts,
                  actionLabel: 'Thêm tài khoản',
                  onAction: _openAddAccount,
                )
              else ...[
                _buildAccountGroup(AppStrings.cashWallet, AccountType.cash, provider),
                _buildAccountGroup(AppStrings.bankAccount, AccountType.bank, provider),
                _buildAccountGroup(AppStrings.creditCard, AccountType.creditCard, provider),
                _buildAccountGroup(AppStrings.eWallet, AccountType.eWallet, provider),
              ],
              const SizedBox(height: 100),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAccount,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm tài khoản', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTotalCard(AccountProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.cardGradientDark : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.dynamicElevatedShadow(isDark),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
          width: 1.5,
        ),
      ),
      child: Column(children: [
        const Text('Tổng số dư', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.format(provider.totalBalance),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text('${provider.totalAccounts} tài khoản đang theo dõi',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ]),
    );
  }

  Widget _buildQuickStats(AccountProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.wallet_outlined,
            label: 'Ví hoạt động',
            value: '${provider.activeWallets}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            icon: Icons.star_outline,
            label: 'Mặc định',
            value: provider.defaultAccount?.name ?? 'Chưa có',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.dynamicCardShadow(isDark),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: hintColor)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountGroup(String title, AccountType type, AccountProvider provider) {
    final accounts = provider.accounts.where((a) => a.type == type).toList();
    if (accounts.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecColor)),
      ),
      ...accounts.map((acc) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildAccountCard(acc),
          )),
      const SizedBox(height: 8),
    ]);
  }

  Widget _buildAccountCard(Account account) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final textPriColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final primarySurfaceColor = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddAccountScreen(existingAccount: account)),
        );
        if (!mounted) return;
        context.read<AccountProvider>().loadAccounts();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.dynamicCardShadow(isDark),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.0,
          ),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(account.color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _accountIcon(account.type),
              color: Color(account.color),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text(account.typeName,
                  style: TextStyle(color: hintColor, fontSize: 12)),
              if (account.isDefault)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primarySurfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Mặc định',
                      style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              CurrencyFormatter.format(account.balance),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: account.balance >= 0 ? textPriColor : AppColors.expense,
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.chevron_right, color: hintColor, size: 18),
          ]),
        ]),
      ),
    );
  }

  IconData _accountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash: return Icons.account_balance_wallet;
      case AccountType.bank: return Icons.account_balance;
      case AccountType.creditCard: return Icons.credit_card;
      case AccountType.eWallet: return Icons.phone_android;
    }
  }

  Future<void> _openAddAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (!mounted) return;
    context.read<AccountProvider>().loadAccounts();
  }
}
