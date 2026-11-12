import 'dart:convert';

class Expense {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String notes;
  final String? employeeId;
  final String? employeeName;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.notes = '',
    this.employeeId,
    this.employeeName,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? notes,
    String? employeeId,
    String? employeeName,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'notes': notes,
      'employeeId': employeeId,
      'employeeName': employeeName,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'نثريات',
      description: map['description'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes'] ?? '',
      employeeId: map['employeeId'],
      employeeName: map['employeeName'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Expense.fromJson(String source) =>
      Expense.fromMap(json.decode(source));
}
