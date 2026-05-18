import 'package:flutter/foundation.dart' hide Category;
import '../data/models/category_model.dart';
import '../data/database/app_database.dart';

class CategoryProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  List<Category> get incomeCategories => _categories.where((c) => c.isIncome).toList();
  List<Category> get expenseCategories => _categories.where((c) => !c.isIncome).toList();

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _db.getCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(Category c) async {
    await _db.insertCategory(c);
    await loadCategories();
  }

  Future<void> updateCategory(Category c) async {
    await _db.updateCategory(c);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await loadCategories();
  }

  Category? getById(String id) {
    try { return _categories.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }
}
