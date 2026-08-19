import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/cards/balance_card.dart';
import '../../widgets/cards/budget_overview_card.dart';
import '../../widgets/cards/transaction_list_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/receipt_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final txProv = context.read<TransactionProvider>();
    final budgetProv = context.read<BudgetProvider>();
    final accProv = context.read<AccountProvider>();
    await Future.wait([
      txProv.loadTransactionsForMonth(_now.year, _now.month),
      budgetProv.loadBudgets(),
      accProv.loadAccounts(),
    ]);
    await budgetProv.refreshBudgetSpending();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const BalanceCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    const BudgetOverviewCard(),
                    const SizedBox(height: 24),
                    _buildRecentTransactions(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddTransaction,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Thêm giao dịch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    const greetingName = 'opps';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final appBarGradient = isDark 
        ? const LinearGradient(
            colors: [Color(0xFF091E36), Color(0xFF0B0F19)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : AppColors.primaryGradient;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: appBarGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_getGreeting()}, $greetingName!',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormatter.monthName(_now.month)} ${_now.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: AppStrings.settings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;

    final actions = [
      {
        'icon': Icons.arrow_upward_rounded,
        'label': 'Thu nhập',
        'gradient': AppColors.incomeGradient,
        'type': TransactionType.income,
      },
      {
        'icon': Icons.arrow_downward_rounded,
        'label': 'Chi tiêu',
        'gradient': AppColors.expenseGradient,
        'type': TransactionType.expense,
      },
      {
        'icon': Icons.swap_horiz_rounded,
        'label': 'Chuyển ví',
        'gradient': const LinearGradient(
          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'type': TransactionType.transfer,
      },
      {
        'icon': Icons.qr_code_scanner_rounded,
        'label': 'Quét HĐ',
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'type': null,
      },
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (action['type'] != null) {
                _navigateToAddTransaction(
                  type: action['type'] as TransactionType,
                );
              } else {
                _navigateToReceiptScan();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.dynamicCardShadow(isDark),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: action['gradient'] as LinearGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (action['gradient'] as LinearGradient).colors.first.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;

    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final recent = provider.recentTransactions;
        return Column(
          children: [
            SectionHeader(
              title: AppStrings.recentTransactions,
              onSeeAll: () => widget.onNavigateToTab?.call(1),
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            else if (recent.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_rounded,
                message: AppStrings.noTransactions,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = recent[index];
                  return TransactionListTile(
                    transaction: t,
                    category: provider.getCategoryById(t.categoryId),
                    account: provider.getAccountById(t.accountId),
                    onTap: () => _navigateToEditTransaction(t),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _navigateToAddTransaction({TransactionType? type}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToEditTransaction(dynamic t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(existingTransaction: t),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _navigateToReceiptScan() async {
    final draft = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScanScreen()),
    );
    if (!mounted || draft == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialType: TransactionType.expense,
          initialAmount: draft.amount,
          initialNote: draft.note,
          receiptImagePath: draft.receiptImagePath,
        ),
      ),
    ).then((_) => _loadData());
  }
}
