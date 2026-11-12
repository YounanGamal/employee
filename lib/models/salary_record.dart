import 'dart:convert';

class SalaryRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String month;
  final double basicSalary;
  final double additions;
  final double deductions;
  final double advancesDeducted;
  final bool isPaid;
  final String paymentMethod;
  final DateTime? paymentDate;
  final String notes;
  final String? advanceId;

  SalaryRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.basicSalary,
    this.additions = 0.0,
    this.deductions = 0.0,
    this.advancesDeducted = 0.0,
    this.isPaid = false,
    this.paymentMethod = 'كاش',
    this.paymentDate,
    this.notes = '',
    this.advanceId,
  });

  double get netSalary =>
      (basicSalary + additions - deductions - advancesDeducted);

  SalaryRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? month,
    double? basicSalary,
    double? additions,
    double? deductions,
    double? advancesDeducted,
    bool? isPaid,
    String? paymentMethod,
    DateTime? paymentDate,
    String? notes,
    String? advanceId,
  }) {
    return SalaryRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      month: month ?? this.month,
      basicSalary: basicSalary ?? this.basicSalary,
      additions: additions ?? this.additions,
      deductions: deductions ?? this.deductions,
      advancesDeducted: advancesDeducted ?? this.advancesDeducted,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      advanceId: advanceId ?? this.advanceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'month': month,
      'basicSalary': basicSalary,
      'additions': additions,
      'deductions': deductions,
      'advancesDeducted': advancesDeducted,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate?.toIso8601String(),
      'notes': notes,
      'advanceId': advanceId,
    };
  }

  factory SalaryRecord.fromMap(Map<String, dynamic> map) {
    return SalaryRecord(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      month: map['month'] ?? '',
      basicSalary: (map['basicSalary'] as num?)?.toDouble() ?? 0.0,
      additions: (map['additions'] as num?)?.toDouble() ?? 0.0,
      deductions: (map['deductions'] as num?)?.toDouble() ?? 0.0,
      advancesDeducted: (map['advancesDeducted'] as num?)?.toDouble() ?? 0.0,
      isPaid: map['isPaid'] ?? false,
      paymentMethod: map['paymentMethod'] ?? 'كاش',
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate'])
          : null,
      notes: map['notes'] ?? '',
      advanceId: map['advanceId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SalaryRecord.fromJson(String source) =>
      SalaryRecord.fromMap(json.decode(source));
}
