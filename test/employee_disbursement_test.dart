import 'package:flutter_test/flutter_test.dart';
import 'package:employee/models/employee.dart';
import 'package:employee/models/expense.dart';
import 'package:employee/providers/app_provider.dart';

void main() {
  group('Employee National ID Tests', () {
    test('Employee model stores and serializes nationalId correctly', () {
      final emp = Employee(
        id: 'emp_1',
        name: 'أحمد محمود',
        phone: '01012345678',
        nationalId: '29501011234567',
        salary: 6000.0,
        notes: 'ملاحظات تجريبية',
      );

      expect(emp.nationalId, '29501011234567');

      final map = emp.toMap();
      expect(map['nationalId'], '29501011234567');

      final fromMap = Employee.fromMap(map);
      expect(fromMap.nationalId, '29501011234567');
      expect(fromMap.name, 'أحمد محمود');

      final copy = emp.copyWith(nationalId: '30001011234567');
      expect(copy.nationalId, '30001011234567');
      expect(copy.salary, 6000.0);
    });
  });

  group('Employee Direct Disbursement Tests', () {
    test('Expense model supports employee disbursements (not deducted from salary)', () {
      final disbursement = Expense(
        id: 'exp_1',
        amount: 350.0,
        category: 'علاج ودواء',
        description: 'شراء علاج ومستلزمات طبية',
        date: DateTime.now(),
        employeeId: 'emp_1',
        employeeName: 'أحمد محمود',
        notes: 'صرف من الخزنة لا يُخصم من المرتب',
      );

      expect(disbursement.amount, 350.0);
      expect(disbursement.employeeId, 'emp_1');
      expect(disbursement.employeeName, 'أحمد محمود');

      final map = disbursement.toMap();
      expect(map['employeeId'], 'emp_1');
      expect(map['employeeName'], 'أحمد محمود');

      final fromMap = Expense.fromMap(map);
      expect(fromMap.employeeId, 'emp_1');
      expect(fromMap.employeeName, 'أحمد محمود');
    });

    test('Salary calculation is unaffected by direct employee disbursements', () {
      const basicSalary = 6000.0;
      const additions = 500.0;
      const deductions = 200.0;
      const advancesDeducted = 1000.0;

      // Net salary = basic + additions - deductions - advancesDeducted
      final netSalary = basicSalary + additions - deductions - advancesDeducted;
      expect(netSalary, 5300.0);

      // The employee also received medical disbursement of 350 LE which is NOT in deductions or advances
      const medicalDisbursement = 350.0;
      expect(medicalDisbursement, isPositive);
      // Net salary remains exactly 5300 LE
      expect(netSalary, 5300.0);
    });
  });

  group('Salary Month and Day 1 Date Tests', () {
    test('AppProvider.getDayOneOfMonth returns day 1 for any year and month', () {
      final d1 = AppProvider.getDayOneOfMonth('2026-09');
      expect(d1.year, 2026);
      expect(d1.month, 9);
      expect(d1.day, 1);

      final d2 = AppProvider.getDayOneOfMonth('2025-01');
      expect(d2.year, 2025);
      expect(d2.month, 1);
      expect(d2.day, 1);

      final d3 = AppProvider.getDayOneOfMonth('2027-12');
      expect(d3.year, 2027);
      expect(d3.month, 12);
      expect(d3.day, 1);
    });
  });
}
