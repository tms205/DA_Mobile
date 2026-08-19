import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/category_model.dart';
import '../../providers/category_provider.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? existingCategory;
  final bool isIncome;
  const AddCategoryScreen({
    super.key,
    this.existingCategory,
    this.isIncome = false,
  });

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = AppColors.primary;
  IconData _selectedIcon = Icons.category;
  bool _isSaving = false;

  static const _colors = [
    AppColors.primary,
    Color(0xFF29B6F6),
    Color(0xFFFFB347),
    Color(0xFFE53935),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF7043),
    Color(0xFF4CAF7D),
    Color(0xFFE91E63),
  ];

  static const _icons = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.movie,
    Icons.local_hospital,
    Icons.school,
    Icons.receipt,
    Icons.home,
    Icons.more_horiz,
    Icons.account_balance_wallet,
    Icons.card_giftcard,
    Icons.laptop,
    Icons.trending_up,
    Icons.attach_money,
    Icons.fitness_center,
    Icons.flight,
    Icons.pets,
    Icons.music_note,
    Icons.sports_soccer,
    Icons.coffee,
    Icons.local_pharmacy,
    Icons.computer,
    Icons.wifi,
    Icons.phone,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      final cat = widget.existingCategory!;
      _nameController.text = cat.name;
      _selectedColor = cat.colorValue;
      _selectedIcon = cat.iconData;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCategory != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? AppStrings.editCategory : AppStrings.addCategory,
        ),
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
            // Preview
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_selectedIcon, color: _selectedColor, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildColorSelector(),
            const SizedBox(height: 16),
            _buildIconSelector(),
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
            AppStrings.categoryName,
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
              hintText: 'Nhập tên danh mục',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            validator: (v) =>
                v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
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
            spacing: 10,
            runSpacing: 10,
            children: _colors.map((c) {
              final isSelected = _selectedColor.toARGB32() == c.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.6),
                              blurRadius: 8,
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

  Widget _buildIconSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.categoryIcon,
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _icons.length,
            itemBuilder: (context, i) {
              final icon = _icons[i];
              final isSelected = _selectedIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedColor.withValues(alpha: 0.15)
                        : surfaceVariantColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? _selectedColor
                        : textSecColor,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final category = Category(
        id: widget.existingCategory?.id,
        name: _nameController.text,
        icon: '${_selectedIcon.codePoint}',
        color: _selectedColor.toARGB32(),
        isIncome: widget.existingCategory?.isIncome ?? widget.isIncome,
      );
      final provider = context.read<CategoryProvider>();
      if (widget.existingCategory != null) {
        await provider.updateCategory(category);
      } else {
        await provider.addCategory(category);
      }
      if (mounted) Navigator.pop(context, category);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final category = widget.existingCategory;
    if (category == null || category.isDefault) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa danh mục'),
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
      await context.read<CategoryProvider>().deleteCategory(category.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
