import 'dart:convert';

class Income {
  final String id;
  final double amount;
  final String reason;
  final DateTime date;
  final String notes;

  Income({
    required this.id,
    required this.amount,
    required this.reason,
    required this.date,
    this.notes = '',
  });

  Income copyWith({
    String? id,
    double? amount,
    String? reason,
    DateTime? date,
    String? notes,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'reason': reason,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Income.fromJson(String source) => Income.fromMap(json.decode(source));
}
