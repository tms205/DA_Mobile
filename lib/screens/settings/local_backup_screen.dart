import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/local_backup_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';

class LocalBackupScreen extends StatefulWidget {
  const LocalBackupScreen({super.key});

  @override
  State<LocalBackupScreen> createState() => _LocalBackupScreenState();
}

class _LocalBackupScreenState extends State<LocalBackupScreen> {
  final _service = LocalBackupService();

  BackupSnapshotStatus _status = const BackupSnapshotStatus(hasBackup: false);
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sao lưu dữ liệu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 12),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.backup_outlined,
            title: 'Tạo bản sao lưu mới',
            subtitle: 'Lưu ảnh chụp dữ liệu hiện tại vào bộ nhớ cục bộ của ứng dụng.',
            buttonLabel: 'Sao lưu ngay',
            onPressed: _backup,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.restore_outlined,
            title: 'Khôi phục bản sao lưu gần nhất',
            subtitle: 'Ghi đè dữ liệu hiện tại bằng bản sao lưu đã lưu trong máy.',
            buttonLabel: 'Khôi phục',
            onPressed: _restore,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.sd_storage_outlined, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trạng thái sao lưu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _status.hasBackup
                      ? 'Lần cuối: ${DateFormatter.formatDateTime(_status.backedUpAt!)}'
                      : 'Chưa có bản sao lưu',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _status.hasBackup
                      ? 'Tổng ${_status.recordCount} bản ghi'
                      : 'Dữ liệu sẽ được lưu cùng thiết bị hiện tại',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dữ liệu sao lưu nằm trong bộ nhớ cục bộ của ứng dụng. '
              'Nếu gỡ ứng dụng hoặc xóa dữ liệu app, bản sao lưu này cũng sẽ mất.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Future<void> Function() onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _isBusy ? null : onPressed,
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadStatus() async {
    final status = await _service.getBackupStatus();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _backup() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isBusy = true);
    try {
      final status = await _service.createBackup();
      if (!mounted) return;
      setState(() => _status = status);
      messenger.showSnackBar(
        SnackBar(content: Text('Đã sao lưu ${status.recordCount} bản ghi')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restore() async {
    if (!_status.hasBackup) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có bản sao lưu')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final providers = _captureProviders();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu'),
        content: const Text(
          'Dữ liệu hiện tại sẽ bị ghi đè bằng bản sao lưu gần nhất. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final result = await _service.restoreLatestBackup();
      if (!result.restored) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Không thể khôi phục dữ liệu'),
          ),
        );
        return;
      }

      await _reloadProviders(providers);
      await _loadStatus();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã khôi phục ${result.recordCount} bản ghi thành công'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  _ProviderBundle _captureProviders() {
    return _ProviderBundle(
      transactionProvider: context.read<TransactionProvider>(),
      accountProvider: context.read<AccountProvider>(),
      budgetProvider: context.read<BudgetProvider>(),
      categoryProvider: context.read<CategoryProvider>(),
    );
  }

  Future<void> _reloadProviders(_ProviderBundle providers) async {
    final now = DateTime.now();
    await Future.wait([
      providers.transactionProvider.loadTransactionsForMonth(now.year, now.month),
      providers.accountProvider.loadAccounts(),
      providers.budgetProvider.loadBudgets(),
      providers.categoryProvider.loadCategories(),
    ]);
    await providers.budgetProvider.refreshBudgetSpending();
  }
}

class _ProviderBundle {
  const _ProviderBundle({
    required this.transactionProvider,
    required this.accountProvider,
    required this.budgetProvider,
    required this.categoryProvider,
  });

  final TransactionProvider transactionProvider;
  final AccountProvider accountProvider;
  final BudgetProvider budgetProvider;
  final CategoryProvider categoryProvider;
}
