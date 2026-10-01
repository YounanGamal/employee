import 'dart:convert';

class Employee {
  final String id;
  final String name;
  final String phone;
  final String nationalId;
  final double salary;
  final String notes;
  final bool isActive;
  final DateTime joinedDate;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    this.nationalId = '',
    required this.salary,
    this.notes = '',
    this.isActive = true,
    DateTime? joinedDate,
  }) : joinedDate = joinedDate ?? DateTime.now();

  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    String? nationalId,
    double? salary,
    String? notes,
    bool? isActive,
    DateTime? joinedDate,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      salary: salary ?? this.salary,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'nationalId': nationalId,
      'salary': salary,
      'notes': notes,
      'isActive': isActive,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      nationalId: map['nationalId'] ?? '',
      salary: (map['salary'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      isActive: map['isActive'] ?? true,
      joinedDate: map['joinedDate'] != null
          ? DateTime.tryParse(map['joinedDate']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Employee.fromJson(String source) =>
      Employee.fromMap(json.decode(source));
}
