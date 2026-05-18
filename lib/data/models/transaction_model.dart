import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TransactionType { income, expense, transfer }

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String accountId;
  final String? toAccountId; // for transfer
  final String note;
  final DateTime date;
  final bool isRecurring;
  final String? recurringInterval; // daily, weekly, monthly
  final String? receiptImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.note = '',
    required this.date,
    this.isRecurring = false,
    this.recurringInterval,
    this.receiptImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? note,
    DateTime? date,
    bool? isRecurring,
    String? recurringInterval,
    String? receiptImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'note': note,
      'date': date.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurringInterval': recurringInterval,
      'receiptImagePath': receiptImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      amount: map['amount'],
      categoryId: map['categoryId'],
      accountId: map['accountId'],
      toAccountId: map['toAccountId'],
      note: map['note'] ?? '',
      date: DateTime.parse(map['date']),
      isRecurring: map['isRecurring'] == 1,
      recurringInterval: map['recurringInterval'],
      receiptImagePath: map['receiptImagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
