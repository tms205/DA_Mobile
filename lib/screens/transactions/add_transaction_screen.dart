import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/services/smart_finance_service.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../categories/add_category_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType? initialType;
  final double? initialAmount;
  final String? initialNote;
  final String? receiptImagePath;
  final Transaction? existingTransaction;

  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.initialAmount,
    this.initialNote,
    this.receiptImagePath,
    this.existingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _noteFocusNode = FocusNode();

  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String? _recurringInterval;
  String? _receiptImagePath;
  CategorySuggestion? _categorySuggestion;
  Timer? _categorySuggestDebounce;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.initialType ??
        widget.existingTransaction?.type ??
        TransactionType.expense;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedType.index,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = TransactionType.values[_tabController.index];
          _selectedCategory = _defaultCategoryForType(
            context.read<CategoryProvider>().categories,
          );
          _categorySuggestion = null;
        });
        _scheduleCategorySuggestion();
      }
    });

    if (widget.existingTransaction != null) {
      final t = widget.existingTransaction!;
      _amountController.text = CurrencyFormatter.plainNumber(t.amount);
      _noteController.text = t.note;
      _selectedDate = t.date;
      _isRecurring = t.isRecurring;
      _recurringInterval = t.recurringInterval;
      _receiptImagePath = t.receiptImagePath;
    } else {
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = CurrencyFormatter.plainNumber(
          widget.initialAmount!,
        );
      }
      _noteController.text = widget.initialNote ?? '';
      _receiptImagePath = widget.receiptImagePath;
    }
    _noteController.addListener(_scheduleCategorySuggestion);
    _noteFocusNode.addListener(() {
      if (!_noteFocusNode.hasFocus) {
        _scheduleCategorySuggestion(force: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final categoryProvider = context.read<CategoryProvider>();
    final accountProvider = context.read<AccountProvider>();
    await Future.wait([
      categoryProvider.loadCategories(),
      accountProvider.loadAccounts(),
    ]);
    final accounts = accountProvider.accounts;
    final cats = categoryProvider.categories;

    if (widget.existingTransaction != null && mounted) {
      final t = widget.existingTransaction!;
      setState(() {
        _selectedCategory = cats.where((c) => c.id == t.categoryId).firstOrNull;
        _selectedAccount = accounts
            .where((a) => a.id == t.accountId)
            .firstOrNull;
        if (t.toAccountId != null) {
          _selectedToAccount = accounts
              .where((a) => a.id == t.toAccountId)
              .firstOrNull;
        }
      });
    } else if (mounted) {
      setState(() {
        _selectedAccount =
            accounts.where((a) => a.isDefault).firstOrNull ??
            (accounts.isNotEmpty ? accounts.first : null);
        _selectedCategory = _defaultCategoryForType(cats);
      });
      _scheduleCategorySuggestion();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categorySuggestDebounce?.cancel();
    _noteController.removeListener(_scheduleCategorySuggestion);
    _noteFocusNode.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTransaction != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? AppStrings.editTransaction : AppStrings.addTransaction,
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: isDark ? AppColors.textPrimaryDark : Colors.white,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTypeTabBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildCategorySelector(),
                    const SizedBox(height: 16),
                    _buildAccountSelector(),
                    if (_selectedType == TransactionType.transfer) ...[
                      const SizedBox(height: 16),
                      _buildToAccountSelector(),
                    ],
                    const SizedBox(height: 16),
                    _buildDatePicker(),
                    const SizedBox(height: 16),
                    _buildNoteField(),
                    if (_receiptImagePath != null) ...[
                      const SizedBox(height: 16),
                      _buildReceiptInfo(),
                    ],
                    const SizedBox(height: 16),
                    _buildRecurringSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = ['Thu nhập', 'Chi tiêu', 'Chuyển khoản'];
    final icons = [Icons.arrow_upward, Icons.arrow_downward, Icons.swap_horiz];

    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.primary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: isDark ? AppColors.accent : Colors.white,
        indicatorWeight: 3,
        labelColor: isDark ? AppColors.accent : Colors.white,
        unselectedLabelColor: isDark ? AppColors.textHintDark : Colors.white54,
        tabs: List.generate(
          3,
          (i) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[i],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    labels[i],
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final color = _selectedType == TransactionType.income
        ? AppColors.income
        : _selectedType == TransactionType.expense
        ? AppColors.expense
        : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(20),
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
            AppStrings.amount,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                CurrencyFormatter.inputSuffix(),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(),
                  ],
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: '0',
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    if (CurrencyFormatter.parse(value) <= 0) {
                      return 'Số tiền không hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_selectedType == TransactionType.transfer) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariantColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;

    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final cats = _selectedType == TransactionType.income
            ? provider.incomeCategories
            : provider.expenseCategories;
        return _buildCard(
          label: AppStrings.category,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_categorySuggestion != null &&
                  _selectedCategory?.id ==
                      _categorySuggestion!.categoryId)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildAiSuggestionBanner(),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...cats.map((cat) {
                      final isSelected = _selectedCategory?.id == cat.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _categorySuggestion = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.colorValue.withValues(alpha: 0.15)
                                : surfaceVariantColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? cat.colorValue
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cat.iconData,
                                size: 18,
                                color: cat.colorValue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? cat.colorValue
                                      : textSecColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: _addNewCategory,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceVariantColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Thêm mới',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addNewCategory() async {
    final isIncome = _selectedType == TransactionType.income;
    final newCategory = await Navigator.push<Category>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(isIncome: isIncome),
      ),
    );

    if (newCategory != null && mounted) {
      setState(() {
        _selectedCategory = newCategory;
        _categorySuggestion = null;
      });
    }
  }

  Widget _buildAiSuggestionBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final suggestion = _categorySuggestion!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.info, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI gợi ý danh mục (${(suggestion.confidence * 100).toStringAsFixed(0)}%) - ${suggestion.reason}',
              style: TextStyle(
                color: textSecColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector() {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) {
        return _buildCard(
          label: AppStrings.account,
          child: _buildDropdown<Account>(
            value: _selectedAccount,
            items: provider.accounts,
            itemLabel: (a) => a.name,
            onChanged: (a) => setState(() => _selectedAccount = a),
            hint: 'Chọn tài khoản',
          ),
        );
      },
    );
  }

  Widget _buildToAccountSelector() {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) {
        return _buildCard(
          label: 'Tài khoản đích',
          child: _buildDropdown<Account>(
            value: _selectedToAccount,
            items: provider.accounts
                .where((a) => a.id != _selectedAccount?.id)
                .toList(),
            itemLabel: (a) => a.name,
            onChanged: (a) => setState(() => _selectedToAccount = a),
            hint: 'Chọn tài khoản đích',
          ),
        );
      },
    );
  }

  Widget _buildDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final textPriColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return _buildCard(
      label: AppStrings.date,
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: primaryColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormatter.formatDate(_selectedDate),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textPriColor,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: hintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return _buildCard(
      label: AppStrings.note,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _noteController,
            focusNode: _noteFocusNode,
            maxLines: 2,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            enableSuggestions: false,
            autocorrect: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: const InputDecoration(
              hintText: 'Thêm ghi chú...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (_categorySuggestion != null) ...[
            const SizedBox(height: 10),
            _buildAiSuggestionBanner(),
          ],
        ],
      ),
    );
  }

  void _scheduleCategorySuggestion({bool force = false}) {
    _categorySuggestDebounce?.cancel();

    final composing = _noteController.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;

    _categorySuggestDebounce = Timer(
      force ? Duration.zero : const Duration(milliseconds: 650),
      _suggestCategoryFromNote,
    );
  }

  void _suggestCategoryFromNote() {
    if (!mounted || _selectedType == TransactionType.transfer) return;

    final composing = _noteController.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;

    final categories = _categoriesForSelectedType(
      context.read<CategoryProvider>().categories,
    );
    final suggestion = SmartExpenseClassifier.suggestCategory(
      _noteController.text,
      categories,
      type: _selectedType,
    );
    if (suggestion == null) {
      if (_categorySuggestion != null) {
        setState(() => _categorySuggestion = null);
      }
      return;
    }
    if (_selectedCategory?.id == suggestion.categoryId &&
        _categorySuggestion?.categoryId == suggestion.categoryId) {
      return;
    }
    final category = categories
        .where((c) => c.id == suggestion.categoryId)
        .firstOrNull;
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _categorySuggestion = suggestion;
    });
  }

  List<Category> _categoriesForSelectedType(List<Category> categories) {
    final isIncome = _selectedType == TransactionType.income;
    return categories
        .where((category) => category.isIncome == isIncome)
        .toList();
  }

  Category? _defaultCategoryForType(List<Category> categories) {
    return switch (_selectedType) {
      TransactionType.income => null,
      TransactionType.expense =>
        categories.where((c) => c.id == 'cat_bills').firstOrNull ??
            categories.where((c) => !c.isIncome).firstOrNull,
      TransactionType.transfer => null,
    };
  }

  Widget _buildReceiptInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return _buildCard(
      label: 'Hóa đơn đính kèm',
      child: Row(
        children: [
          Icon(Icons.image_outlined, color: primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _receiptImagePath!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: textSecColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _receiptImagePath = null),
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Gỡ hóa đơn',
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final primarySurfaceColor = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;
    final surfaceVariantColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

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
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: primaryColor, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  AppStrings.recurringTransaction,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Switch(
                value: _isRecurring,
                activeThumbColor: primaryColor,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
            ],
          ),
          if (_isRecurring) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: ['daily', 'weekly', 'monthly'].map((interval) {
                final labels = {
                  'daily': 'Hàng ngày',
                  'weekly': 'Hàng tuần',
                  'monthly': 'Hàng tháng',
                };
                final isSelected = _recurringInterval == interval;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _recurringInterval = interval),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primarySurfaceColor
                            : surfaceVariantColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        labels[interval]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? primaryColor
                              : textSecColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
        label: Text(
          widget.existingTransaction != null ? 'Cập nhật' : AppStrings.save,
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCard({required String label, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return Container(
      width: double.infinity,
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final dropdownBg = isDark ? AppColors.surfaceDark : AppColors.surface;

    return DropdownButton<T>(
      value: value,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      dropdownColor: dropdownBg,
      hint: Text(hint, style: TextStyle(color: hintColor)),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: AppColors.accent,
                  onPrimary: Colors.white,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textPrimaryDark,
                )
              : const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _noteFocusNode.unfocus();
    _suggestCategoryFromNote();

    if (_selectedCategory == null &&
        _selectedType != TransactionType.transfer) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tài khoản')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final amount = CurrencyFormatter.parseToBase(_amountController.text);
      final transaction = Transaction(
        id: widget.existingTransaction?.id,
        type: _selectedType,
        amount: amount,
        categoryId: _selectedCategory?.id ?? 'cat_other_expense',
        accountId: _selectedAccount!.id,
        toAccountId: _selectedToAccount?.id,
        note: _noteController.text,
        date: _selectedDate,
        isRecurring: _isRecurring,
        recurringInterval: _isRecurring ? _recurringInterval : null,
        receiptImagePath: _receiptImagePath,
      );

      final provider = context.read<TransactionProvider>();
      if (widget.existingTransaction != null) {
        await provider.updateTransaction(
          widget.existingTransaction!,
          transaction,
        );
      } else {
        await provider.addTransaction(transaction);
      }
      if (!mounted) return;
      await _refreshImpactedData();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _refreshImpactedData() async {
    final accountProvider = context.read<AccountProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    await Future.wait([
      accountProvider.loadAccounts(),
      budgetProvider.refreshBudgetSpending(),
    ]);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch'),
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
      await context.read<TransactionProvider>().deleteTransaction(
        widget.existingTransaction!,
      );
      if (!mounted) return;
      await _refreshImpactedData();
      if (mounted) Navigator.pop(context);
    }
  }
}
