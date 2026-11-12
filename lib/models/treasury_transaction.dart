import 'dart:convert';

enum TransactionType {
  income,
  expense,
  salary,
  advancePayout,
  advanceRepayment,
  adjustment,
}

class TreasuryTransaction {
  final String id;
  final DateTime date;
  final TransactionType type;
  final double amount;
  final bool isCredit;
  final String title;
  final String notes;
  final String? referenceId;

  TreasuryTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.isCredit,
    required this.title,
    this.notes = '',
    this.referenceId,
  });

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
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'amount': amount,
      'isCredit': isCredit,
      'title': title,
      'notes': notes,
      'referenceId': referenceId,
    };
  }

  factory TreasuryTransaction.fromMap(Map<String, dynamic> map) {
    TransactionType tType = TransactionType.income;
    try {
      tType = TransactionType.values.byName(map['type'] ?? 'income');
    } catch (_) {
      tType = TransactionType.income;
    }

    return TreasuryTransaction(
      id: map['id'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      type: tType,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isCredit: map['isCredit'] ?? true,
      title: map['title'] ?? '',
      notes: map['notes'] ?? '',
      referenceId: map['referenceId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TreasuryTransaction.fromJson(String source) =>
      TreasuryTransaction.fromMap(json.decode(source));
}
