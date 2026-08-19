import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/account_model.dart';
import '../../providers/account_provider.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? existingAccount;
  const AddAccountScreen({super.key, this.existingAccount});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _selectedType = AccountType.cash;
  Color _selectedColor = AppColors.primary;
  bool _isSaving = false;
  bool _isDefault = false;

  static const List<Color> _colorOptions = [
    AppColors.primary,
    Color(0xFF29B6F6),
    Color(0xFFFFB347),
    Color(0xFFE53935),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF7043),
    Color(0xFF4CAF7D),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingAccount != null) {
      final acc = widget.existingAccount!;
      _nameController.text = acc.name;
      _balanceController.text = CurrencyFormatter.plainNumber(acc.balance);
      _selectedType = acc.type;
      _selectedColor = Color(acc.color);
      _isDefault = acc.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAccount != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.editAccount : AppStrings.addAccount),
        actions: [
          if (isEditing && !widget.existingAccount!.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildBalanceField(),
            const SizedBox(height: 16),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildColorSelector(),
            const SizedBox(height: 16),
            _buildDefaultToggle(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(isEditing ? 'Cập nhật' : AppStrings.save),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.accountName,
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            enableSuggestions: false,
            autocorrect: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: const InputDecoration(
              hintText: 'Ví tiền mặt, Vietcombank, Momo...',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.initialBalance,
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                CurrencyFormatter.inputSuffix(),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(),
                  ],
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final primarySurfaceColor = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;
    final surfaceVariantColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final types = [
      {
        'type': AccountType.cash,
        'label': 'Tiền mặt',
        'icon': Icons.account_balance_wallet,
      },
      {
        'type': AccountType.bank,
        'label': 'Ngân hàng',
        'icon': Icons.account_balance,
      },
      {
        'type': AccountType.creditCard,
        'label': 'Thẻ tín dụng',
        'icon': Icons.credit_card,
      },
      {
        'type': AccountType.eWallet,
        'label': 'Ví điện tử',
        'icon': Icons.phone_android,
      },
    ];
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.accountType,
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3,
            children: types.map((t) {
              final isSelected = _selectedType == t['type'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedType = t['type'] as AccountType),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primarySurfaceColor
                        : surfaceVariantColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        t['icon'] as IconData,
                        size: 18,
                        color: isSelected
                            ? primaryColor
                            : textSecColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? primaryColor
                              : textSecColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.categoryColor,
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((color) {
              final isSelected = _selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Icon(Icons.star_border, color: primaryColor, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Đặt làm tài khoản mặc định',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: _isDefault,
            activeThumbColor: primaryColor,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final account = Account(
        id: widget.existingAccount?.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: CurrencyFormatter.parseToBase(_balanceController.text),
        color: _selectedColor.toARGB32(),
        icon: '${57490}',
        isDefault: _isDefault,
      );
      final provider = context.read<AccountProvider>();
      if (widget.existingAccount != null) {
        await provider.updateAccount(account);
      } else {
        await provider.addAccount(account);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu tài khoản: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AccountProvider>().deleteAccount(
        widget.existingAccount!.id,
      );
      if (mounted) Navigator.pop(context);
    }
  }
}
