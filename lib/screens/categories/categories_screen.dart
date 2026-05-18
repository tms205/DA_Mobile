import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'add_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CategoryProvider>().loadCategories());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.categories),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: AppStrings.incomeCategories),
            Tab(text: AppStrings.expenseCategories),
          ],
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryGrid(provider.incomeCategories),
              _buildCategoryGrid(provider.expenseCategories),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddCategoryScreen(
                isIncome: _tabController.index == 0,
              ),
            ),
          );
          if (!context.mounted) return;
          context.read<CategoryProvider>().loadCategories();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm danh mục', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    if (categories.isEmpty) {
      return const EmptyState(icon: Icons.category, message: 'Chưa có danh mục nào');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) => _buildCategoryCard(categories[i]),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: category.isDefault
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddCategoryScreen(existingCategory: category)),
              );
              if (!mounted) return;
              context.read<CategoryProvider>().loadCategories();
            },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: category.colorValue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category.iconData, color: category.colorValue, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          if (category.isDefault)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.lock_outline, size: 12, color: AppColors.textHint),
            ),
        ]),
      ),
    );
  }
}
