import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../categories/add_category_screen.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? existingBudget;
  const AddBudgetScreen({super.key, this.existingBudget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  Category? _selectedCategory;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _limitController.text = CurrencyFormatter.plainNumber(
        widget.existingBudget!.limit,
      );
      _selectedPeriod = widget.existingBudget!.period;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CategoryProvider>().loadCategories();
      if (widget.existingBudget != null && mounted) {
        setState(() {
          _selectedCategory = context.read<CategoryProvider>().getById(
            widget.existingBudget!.categoryId,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBudget != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.editBudget : AppStrings.addBudget),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildLimitField(),
            const SizedBox(height: 16),
            _buildPeriodSelector(),
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

  Widget _buildCategorySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final surfaceVariantColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final cats = provider.expenseCategories;
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
                AppStrings.category,
                style: TextStyle(
                  fontSize: 12,
                  color: hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isSaving ? null : _addNewCategory,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm danh mục'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (provider.isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                )
              else if (cats.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceVariantColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Chưa có danh mục chi tiêu. Hãy thêm danh mục mới để tạo ngân sách.',
                    style: TextStyle(color: hintColor, height: 1.4),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cats.map((cat) {
                    final isSelected = _selectedCategory?.id == cat.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.iconData, size: 16, color: cat.colorValue),
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
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLimitField() {
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
            AppStrings.budgetLimit,
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
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _limitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(),
                  ],
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập hạn mức';
                    if (CurrencyFormatter.parse(v) <= 0) {
                      return 'Hạn mức không hợp lệ';
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

  Widget _buildPeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final primarySurfaceColor = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;
    final surfaceVariantColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final periods = [
      {'period': BudgetPeriod.weekly, 'label': 'Hàng tuần'},
      {'period': BudgetPeriod.monthly, 'label': 'Hàng tháng'},
      {'period': BudgetPeriod.yearly, 'label': 'Hàng năm'},
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
            AppStrings.budgetPeriod,
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: periods.map((p) {
              final isSelected = _selectedPeriod == p['period'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                    () => _selectedPeriod = p['period'] as BudgetPeriod,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                    child: Text(
                      p['label'] as String,
                      textAlign: TextAlign.center,
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
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  DateTime _getPeriodEnd(BudgetPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.weekly:
        return now.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
      case BudgetPeriod.yearly:
        return DateTime(
          now.year + 1,
          1,
          1,
        ).subtract(const Duration(seconds: 1));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final budget = Budget(
        id: widget.existingBudget?.id,
        categoryId: _selectedCategory!.id,
        limit: CurrencyFormatter.parseToBase(_limitController.text),
        spent: widget.existingBudget?.spent ?? 0,
        period: _selectedPeriod,
        startDate: widget.existingBudget?.startDate ?? now,
        endDate: _getPeriodEnd(_selectedPeriod),
      );
      final provider = context.read<BudgetProvider>();
      if (widget.existingBudget != null) {
        await provider.updateBudget(budget);
      } else {
        await provider.addBudget(budget);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addNewCategory() async {
    final categoryProvider = context.read<CategoryProvider>();
    final createdCategory = await Navigator.push<Category>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCategoryScreen(isIncome: false),
      ),
    );

    if (!mounted) return;

    await categoryProvider.loadCategories();
    if (createdCategory == null) return;

    final latestCategory =
        categoryProvider.getById(createdCategory.id) ?? createdCategory;
    setState(() => _selectedCategory = latestCategory);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ngân sách'),
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
      await context.read<BudgetProvider>().deleteBudget(
        widget.existingBudget!.id,
      );
      if (mounted) Navigator.pop(context);
    }
  }
}
