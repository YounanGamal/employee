import 'dart:convert';
import 'package:intl/intl.dart';

enum TransactionType {
  income,
  expense,
  salary,
  advancePayout,
  advanceRepayment,
  adjustment,
  deposit,
  withdrawal,
}

class TreasuryTransaction {
  final String id;
  final DateTime date;
  final String month; // 'YYYY-MM'
  final TransactionType type;
  final double amount;
  final bool isCredit;
  final String title;
  final String notes;
  final String? referenceId;
  final DateTime createdAt;

  TreasuryTransaction({
    required this.id,
    required this.date,
    String? month,
    required this.type,
    required this.amount,
    required this.isCredit,
    required this.title,
    this.notes = '',
    this.referenceId,
    DateTime? createdAt,
  })  : month = month ?? DateFormat('yyyy-MM').format(date),
        createdAt = createdAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case TransactionType.income:
        return 'وارد';
      case TransactionType.expense:
        return 'مصروف';
      case TransactionType.salary:
        return 'مرتب';
      case TransactionType.advancePayout:
        return 'سلفة';
      case TransactionType.advanceRepayment:
        return 'سداد سلفة';
      case TransactionType.adjustment:
        return 'تسوية رصيد';
      case TransactionType.deposit:
        return 'إيداع نقدي';
      case TransactionType.withdrawal:
        return 'سحب نقدي';
    }
  }

  TreasuryTransaction copyWith({
    String? id,
    DateTime? date,
    String? month,
    TransactionType? type,
    double? amount,
    bool? isCredit,
    String? title,
    String? notes,
    String? referenceId,
    DateTime? createdAt,
  }) {
    return TreasuryTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      month: month ?? this.month,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      isCredit: isCredit ?? this.isCredit,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'month': month,
      'type': type.name,
      'amount': amount,
      'isCredit': isCredit,
      'title': title,
      'notes': notes,
      'referenceId': referenceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TreasuryTransaction.fromMap(Map<String, dynamic> map) {
    TransactionType tType = TransactionType.income;
    try {
      tType = TransactionType.values.byName(map['type'] ?? 'income');
    } catch (_) {
      tType = TransactionType.income;
    }

    final date = map['date'] != null
        ? DateTime.tryParse(map['date']) ?? DateTime.now()
        : DateTime.now();

    final month = map['month'] as String? ?? DateFormat('yyyy-MM').format(date);

    final createdAt = map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt']) ?? date
        : date;

    return TreasuryTransaction(
      id: map['id'] ?? '',
      date: date,
      month: month,
      type: tType,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isCredit: map['isCredit'] ?? true,
      title: map['title'] ?? '',
      notes: map['notes'] ?? '',
      referenceId: map['referenceId'],
      createdAt: createdAt,
    );
  }

  String toJson() => json.encode(toMap());

  factory TreasuryTransaction.fromJson(String source) =>
      TreasuryTransaction.fromMap(json.decode(source));
}
