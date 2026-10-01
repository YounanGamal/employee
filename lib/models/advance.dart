import 'dart:convert';

class Advance {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final DateTime date;
  final double paidAmount;
  final bool autoDeductFromSalary;
  final String notes;

  Advance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.date,
    this.paidAmount = 0.0,
    this.autoDeductFromSalary = true,
    this.notes = '',
  });

  double get remainingAmount => (amount - paidAmount).clamp(0.0, double.infinity);
  bool get isFullyPaid => remainingAmount <= 0.0;

  Advance copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? amount,
    DateTime? date,
    double? paidAmount,
    bool? autoDeductFromSalary,
    String? notes,
  }) {
    return Advance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paidAmount: paidAmount ?? this.paidAmount,
      autoDeductFromSalary: autoDeductFromSalary ?? this.autoDeductFromSalary,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'date': date.toIso8601String(),
      'paidAmount': paidAmount,
      'autoDeductFromSalary': autoDeductFromSalary,
      'notes': notes,
    };
  }

  factory Advance.fromMap(Map<String, dynamic> map) {
    return Advance(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      autoDeductFromSalary: map['autoDeductFromSalary'] ?? true,
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Advance.fromJson(String source) =>
      Advance.fromMap(json.decode(source));
}
