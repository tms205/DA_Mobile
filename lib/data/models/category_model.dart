import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Category {
  final String id;
  final String name;
  final String icon;       // icon code (material icon codepoint as string)
  final int color;         // color value
  final bool isIncome;     // true = thu nhập, false = chi tiêu
  final bool isDefault;
  final DateTime createdAt;

  Category({
    String? id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
    this.isDefault = false,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    bool? isIncome,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isIncome: isIncome ?? this.isIncome,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isIncome': isIncome ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      isIncome: map['isIncome'] == 1,
      isDefault: map['isDefault'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Color get colorValue => Color(color);
  IconData get iconData => IconData(int.parse(icon), fontFamily: 'MaterialIcons');
}

/// Danh mục mặc định khi khởi tạo ứng dụng
class DefaultCategories {
  static List<Category> get all => [...incomeCategories, ...expenseCategories];

  static List<Category> get incomeCategories => [
    Category(id: 'cat_salary', name: 'Lương', icon: '${Icons.account_balance_wallet.codePoint}', color: 0xFF1A6B3C, isIncome: true, isDefault: true),
    Category(id: 'cat_bonus', name: 'Thưởng', icon: '${Icons.card_giftcard.codePoint}', color: 0xFF4CAF7D, isIncome: true, isDefault: true),
    Category(id: 'cat_freelance', name: 'Làm thêm', icon: '${Icons.laptop.codePoint}', color: 0xFF29B6F6, isIncome: true, isDefault: true),
    Category(id: 'cat_investment', name: 'Đầu tư', icon: '${Icons.trending_up.codePoint}', color: 0xFFFFB347, isIncome: true, isDefault: true),
    Category(id: 'cat_other_income', name: 'Thu nhập khác', icon: '${Icons.attach_money.codePoint}', color: 0xFF9C27B0, isIncome: true, isDefault: true),
  ];

  static List<Category> get expenseCategories => [
    Category(id: 'cat_food', name: 'Ăn uống', icon: '${Icons.restaurant.codePoint}', color: 0xFFE53935, isIncome: false, isDefault: true),
    Category(id: 'cat_transport', name: 'Di chuyển', icon: '${Icons.directions_car.codePoint}', color: 0xFF1A6B3C, isIncome: false, isDefault: true),
    Category(id: 'cat_shopping', name: 'Mua sắm', icon: '${Icons.shopping_bag.codePoint}', color: 0xFFFF7043, isIncome: false, isDefault: true),
    Category(id: 'cat_entertainment', name: 'Giải trí', icon: '${Icons.movie.codePoint}', color: 0xFF9C27B0, isIncome: false, isDefault: true),
    Category(id: 'cat_health', name: 'Sức khỏe', icon: '${Icons.local_hospital.codePoint}', color: 0xFFE91E63, isIncome: false, isDefault: true),
    Category(id: 'cat_education', name: 'Giáo dục', icon: '${Icons.school.codePoint}', color: 0xFF29B6F6, isIncome: false, isDefault: true),
    Category(id: 'cat_bills', name: 'Hóa đơn', icon: '${Icons.receipt.codePoint}', color: 0xFFFFB347, isIncome: false, isDefault: true),
    Category(id: 'cat_housing', name: 'Nhà ở', icon: '${Icons.home.codePoint}', color: 0xFF4CAF7D, isIncome: false, isDefault: true),
    Category(id: 'cat_other_expense', name: 'Chi phí khác', icon: '${Icons.more_horiz.codePoint}', color: 0xFF9E9E9E, isIncome: false, isDefault: true),
  ];
}
