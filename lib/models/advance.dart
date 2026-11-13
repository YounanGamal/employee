import 'dart:convert';
import 'package:intl/intl.dart';

class Advance {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final DateTime date;
  final String month; // Financial period month 'YYYY-MM'
  final double paidAmount;
  final bool autoDeductFromSalary;
  final String notes;
  final bool isOutstanding; // Exceptional case: marked as outstanding / uncollected
  final String statusNotes; // Audit note / settlement reason
  final DateTime createdAt;

  Advance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.date,
    String? month,
    this.paidAmount = 0.0,
    this.autoDeductFromSalary = true,
    this.notes = '',
    this.isOutstanding = false,
    this.statusNotes = '',
    DateTime? createdAt,
  })  : month = month ?? DateFormat('yyyy-MM').format(date),
        createdAt = createdAt ?? DateTime.now();

  double get remainingAmount =>
      (amount - paidAmount).clamp(0.0, double.infinity);
  bool get isFullyPaid => remainingAmount <= 0.0;

  Advance copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? amount,
    DateTime? date,
    String? month,
    double? paidAmount,
    bool? autoDeductFromSalary,
    String? notes,
    bool? isOutstanding,
    String? statusNotes,
    DateTime? createdAt,
  }) {
    return Advance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      month: month ?? this.month,
      paidAmount: paidAmount ?? this.paidAmount,
      autoDeductFromSalary: autoDeductFromSalary ?? this.autoDeductFromSalary,
      notes: notes ?? this.notes,
      isOutstanding: isOutstanding ?? this.isOutstanding,
      statusNotes: statusNotes ?? this.statusNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'date': date.toIso8601String(),
      'month': month,
      'paidAmount': paidAmount,
      'autoDeductFromSalary': autoDeductFromSalary,
      'notes': notes,
      'isOutstanding': isOutstanding,
      'statusNotes': statusNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Advance.fromMap(Map<String, dynamic> map) {
    final date = map['date'] != null
        ? DateTime.tryParse(map['date']) ?? DateTime.now()
        : DateTime.now();

    final month = map['month'] as String? ?? DateFormat('yyyy-MM').format(date);
    final createdAt = map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt']) ?? date
        : date;

    return Advance(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: date,
      month: month,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      autoDeductFromSalary: map['autoDeductFromSalary'] ?? true,
      notes: map['notes'] ?? '',
      isOutstanding: map['isOutstanding'] ?? false,
      statusNotes: map['statusNotes'] ?? '',
      createdAt: createdAt,
    );
  }

  String toJson() => json.encode(toMap());

  factory Advance.fromJson(String source) =>
      Advance.fromMap(json.decode(source));
}
