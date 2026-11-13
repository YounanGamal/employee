import 'dart:convert';

class SalaryPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String notes;

  SalaryPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.paymentMethod = 'كاش',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory SalaryPayment.fromMap(Map<String, dynamic> map) {
    return SalaryPayment(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'كاش',
      notes: map['notes'] ?? '',
    );
  }
}

class SalaryAuditEntry {
  final DateTime timestamp;
  final String action;
  final String details;

  SalaryAuditEntry({
    required this.timestamp,
    required this.action,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'details': details,
    };
  }

  factory SalaryAuditEntry.fromMap(Map<String, dynamic> map) {
    return SalaryAuditEntry(
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      action: map['action'] ?? '',
      details: map['details'] ?? '',
    );
  }
}

class SalaryRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String month; // Financial period 'YYYY-MM'
  final double basicSalary;
  final double additions;
  final double deductions;
  final double advancesDeducted;
  final double paidAmount;
  final List<SalaryPayment> payments;
  final List<SalaryAuditEntry> auditLog;
  final String paymentMethod;
  final DateTime? paymentDate;
  final String notes;
  final String? advanceId;
  final DateTime createdAt;

  SalaryRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.basicSalary,
    this.additions = 0.0,
    this.deductions = 0.0,
    this.advancesDeducted = 0.0,
    double? paidAmount,
    bool isPaid = false,
    List<SalaryPayment>? payments,
    List<SalaryAuditEntry>? auditLog,
    this.paymentMethod = 'كاش',
    this.paymentDate,
    this.notes = '',
    this.advanceId,
    DateTime? createdAt,
  })  : paidAmount = paidAmount ??
            (isPaid ? (basicSalary + additions - deductions - advancesDeducted).clamp(0.0, double.infinity) : 0.0),
        payments = payments ?? [],
        auditLog = auditLog ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get netSalary =>
      (basicSalary + additions - deductions - advancesDeducted);

  bool get isFullyPaid => netSalary > 0 && paidAmount >= netSalary;
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < netSalary;
  bool get isUnpaid => paidAmount <= 0;
  bool get isPaid => isFullyPaid || paidAmount > 0;

  double get remainingUnpaidSalary =>
      (netSalary - paidAmount).clamp(0.0, double.infinity);

  String get statusLabel {
    if (isFullyPaid) return 'مدفوع بالكامل';
    if (isPartiallyPaid) return 'مدفوع جزئياً';
    return 'غير مدفوع';
  }

  SalaryRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? month,
    double? basicSalary,
    double? additions,
    double? deductions,
    double? advancesDeducted,
    double? paidAmount,
    bool? isPaid,
    List<SalaryPayment>? payments,
    List<SalaryAuditEntry>? auditLog,
    String? paymentMethod,
    DateTime? paymentDate,
    String? notes,
    String? advanceId,
    DateTime? createdAt,
  }) {
    final effectivePaid = paidAmount ??
        (isPaid != null
            ? (isPaid
                ? (basicSalary ?? this.basicSalary + (additions ?? this.additions) - (deductions ?? this.deductions) - (advancesDeducted ?? this.advancesDeducted))
                : 0.0)
            : this.paidAmount);

    return SalaryRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      month: month ?? this.month,
      basicSalary: basicSalary ?? this.basicSalary,
      additions: additions ?? this.additions,
      deductions: deductions ?? this.deductions,
      advancesDeducted: advancesDeducted ?? this.advancesDeducted,
      paidAmount: effectivePaid,
      payments: payments ?? this.payments,
      auditLog: auditLog ?? this.auditLog,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      advanceId: advanceId ?? this.advanceId,
      createdAt: createdAt ?? this.createdAt,
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
      'paidAmount': paidAmount,
      'isPaid': isFullyPaid,
      'payments': payments.map((p) => p.toMap()).toList(),
      'auditLog': auditLog.map((a) => a.toMap()).toList(),
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate?.toIso8601String(),
      'notes': notes,
      'advanceId': advanceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SalaryRecord.fromMap(Map<String, dynamic> map) {
    final basic = (map['basicSalary'] as num?)?.toDouble() ?? 0.0;
    final additions = (map['additions'] as num?)?.toDouble() ?? 0.0;
    final deductions = (map['deductions'] as num?)?.toDouble() ?? 0.0;
    final advancesDeducted =
        (map['advancesDeducted'] as num?)?.toDouble() ?? 0.0;
    final calculatedNet = (basic + additions - deductions - advancesDeducted);

    final legacyIsPaid = map['isPaid'] as bool? ?? false;
    final paidAmount = map['paidAmount'] != null
        ? (map['paidAmount'] as num).toDouble()
        : (legacyIsPaid ? calculatedNet : 0.0);

    List<SalaryPayment> paymentsList = [];
    if (map['payments'] != null) {
      final List list = map['payments'];
      paymentsList = list.map((p) => SalaryPayment.fromMap(p)).toList();
    } else if (legacyIsPaid && paidAmount > 0) {
      paymentsList.add(
        SalaryPayment(
          id: 'pay_${map['id'] ?? 'legacy'}',
          amount: paidAmount,
          date: map['paymentDate'] != null
              ? DateTime.tryParse(map['paymentDate']) ?? DateTime.now()
              : DateTime.now(),
          paymentMethod: map['paymentMethod'] ?? 'كاش',
          notes: map['notes'] ?? 'سداد مسجل سابقاً',
        ),
      );
    }

    List<SalaryAuditEntry> auditList = [];
    if (map['auditLog'] != null) {
      final List list = map['auditLog'];
      auditList = list.map((a) => SalaryAuditEntry.fromMap(a)).toList();
    }

    return SalaryRecord(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      month: map['month'] ?? '',
      basicSalary: basic,
      additions: additions,
      deductions: deductions,
      advancesDeducted: advancesDeducted,
      paidAmount: paidAmount,
      isPaid: legacyIsPaid || (paidAmount >= calculatedNet && calculatedNet > 0),
      payments: paymentsList,
      auditLog: auditList,
      paymentMethod: map['paymentMethod'] ?? 'كاش',
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate'])
          : null,
      notes: map['notes'] ?? '',
      advanceId: map['advanceId'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SalaryRecord.fromJson(String source) =>
      SalaryRecord.fromMap(json.decode(source));
}
