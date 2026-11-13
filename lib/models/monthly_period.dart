import 'dart:convert';

class MonthlyPeriod {
  final String month; // Format: 'YYYY-MM', e.g. '2026-11'
  final double openingBalance; // Opening treasury balance for this month (default 0.0)
  final DateTime createdAt;
  final bool isClosed;
  final DateTime? closedAt;
  final String notes;

  MonthlyPeriod({
    required this.month,
    this.openingBalance = 0.0,
    DateTime? createdAt,
    this.isClosed = false,
    this.closedAt,
    this.notes = '',
  }) : createdAt = createdAt ?? DateTime.now();

  MonthlyPeriod copyWith({
    String? month,
    double? openingBalance,
    DateTime? createdAt,
    bool? isClosed,
    DateTime? closedAt,
    String? notes,
  }) {
    return MonthlyPeriod(
      month: month ?? this.month,
      openingBalance: openingBalance ?? this.openingBalance,
      createdAt: createdAt ?? this.createdAt,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'openingBalance': openingBalance,
      'createdAt': createdAt.toIso8601String(),
      'isClosed': isClosed,
      'closedAt': closedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory MonthlyPeriod.fromMap(Map<String, dynamic> map) {
    return MonthlyPeriod(
      month: map['month'] ?? '',
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isClosed: map['isClosed'] ?? false,
      closedAt: map['closedAt'] != null
          ? DateTime.tryParse(map['closedAt'])
          : null,
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MonthlyPeriod.fromJson(String source) =>
      MonthlyPeriod.fromMap(json.decode(source));
}
