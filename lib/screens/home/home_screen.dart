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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
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
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm giao dịch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    const greetingName = 'Nhóm 9';

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${AppStrings.greeting}, $greetingName!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormatter.monthName(_now.month)} ${_now.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
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
    final actions = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'Thu nhập',
        'color': AppColors.income,
        'type': TransactionType.income,
      },
      {
        'icon': Icons.remove_circle_outline,
        'label': 'Chi tiêu',
        'color': AppColors.expense,
        'type': TransactionType.expense,
      },
      {
        'icon': Icons.swap_horiz,
        'label': 'Chuyển khoản',
        'color': AppColors.info,
        'type': TransactionType.transfer,
      },
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Quét HĐ',
        'color': AppColors.warning,
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
              margin: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minHeight: 82),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action['label'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else if (recent.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long,
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
