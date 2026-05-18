import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum BudgetPeriod { weekly, monthly, yearly }

class Budget {
  final String id;
  final String categoryId;
  final double limit;
  final double spent;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    String? id,
    required this.categoryId,
    required this.limit,
    this.spent = 0.0,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get remaining => limit - spent;
  double get percentage => limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => spent > limit;
  bool get isWarning => percentage >= 0.8 && !isExceeded;

  Budget copyWith({
    String? id,
    String? categoryId,
    double? limit,
    double? spent,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'limit': limit,
      'spent': spent,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      categoryId: map['categoryId'],
      limit: map['limit'],
      spent: map['spent'] ?? 0.0,
      period: BudgetPeriod.values.firstWhere((e) => e.name == map['period']),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  String get periodName {
    switch (period) {
      case BudgetPeriod.weekly: return 'Hàng tuần';
      case BudgetPeriod.monthly: return 'Hàng tháng';
      case BudgetPeriod.yearly: return 'Hàng năm';
    }
  }
}
