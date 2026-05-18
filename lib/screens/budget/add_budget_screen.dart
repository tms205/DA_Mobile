import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';

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
      _limitController.text = CurrencyFormatter.plainNumber(widget.existingBudget!.limit);
      _selectedPeriod = widget.existingBudget!.period;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CategoryProvider>().loadCategories();
      if (widget.existingBudget != null && mounted) {
        setState(() {
          _selectedCategory = context.read<CategoryProvider>().getById(widget.existingBudget!.categoryId);
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
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(isEditing ? 'Cập nhật' : AppStrings.save),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(builder: (context, provider, _) {
      final cats = provider.expenseCategories;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.category,
                style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((cat) {
                final isSelected = _selectedCategory?.id == cat.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? cat.colorValue.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? cat.colorValue : Colors.transparent, width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(cat.iconData, size: 16, color: cat.colorValue),
                      const SizedBox(width: 6),
                      Text(cat.name, style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? cat.colorValue : AppColors.textSecondary,
                      )),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLimitField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(AppStrings.budgetLimit,
            style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          Text(CurrencyFormatter.inputSuffix(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),
              decoration: const InputDecoration(
                border: InputBorder.none, hintText: '0',
                filled: false, contentPadding: EdgeInsets.zero,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập hạn mức';
                if (CurrencyFormatter.parse(v) <= 0) return 'Hạn mức không hợp lệ';
                return null;
              },
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'period': BudgetPeriod.weekly, 'label': 'Hàng tuần'},
      {'period': BudgetPeriod.monthly, 'label': 'Hàng tháng'},
      {'period': BudgetPeriod.yearly, 'label': 'Hàng năm'},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(AppStrings.budgetPeriod,
            style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          children: periods.map((p) {
            final isSelected = _selectedPeriod == p['period'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = p['period'] as BudgetPeriod),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primarySurface : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent),
                  ),
                  child: Text(p['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    )),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  DateTime _getPeriodEnd(BudgetPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.weekly:
        return now.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
      case BudgetPeriod.yearly:
        return DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')));
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
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ngân sách'),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<BudgetProvider>().deleteBudget(widget.existingBudget!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
