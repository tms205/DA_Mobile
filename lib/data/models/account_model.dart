import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AccountType { cash, bank, creditCard, eWallet }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final int color;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    String? id,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    int? color,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
      'color': color,
      'icon': icon,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: AccountType.values.firstWhere((e) => e.name == map['type']),
      balance: map['balance'],
      color: map['color'],
      icon: map['icon'],
      isDefault: map['isDefault'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  String get typeName {
    switch (type) {
      case AccountType.cash: return 'Tiền mặt';
      case AccountType.bank: return 'Ngân hàng';
      case AccountType.creditCard: return 'Thẻ tín dụng';
      case AccountType.eWallet: return 'Ví điện tử';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
