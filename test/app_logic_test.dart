import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:employee/providers/app_provider.dart';
import 'package:employee/models/employee.dart';
import 'package:employee/models/advance.dart';
import 'package:employee/models/expense.dart';
import 'package:employee/models/treasury_transaction.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Requirement 1 & 2: Monthly Financial Periods & Treasury Reset to Zero', () {
    test('Treasury resets to 0 automatically in new month and does not carry over previous balance', () async {
      final provider = AppProvider();
      await provider.init();

      // November:
      await provider.setSelectedMonth('2026-11');
      await provider.setPeriodOpeningBalance('2026-11', 50000.0);
      expect(provider.currentTreasuryBalance, equals(50000.0));

      // November expenses: 40,000 EGP
      await provider.addExpense(
        Expense(
          id: 'exp_nov_1',
          amount: 40000.0,
          category: 'تشغيل',
          description: 'مصاريف تشغيل شهر نوفمبر',
          date: DateTime(2026, 11, 15),
        ),
      );

      // November Closing balance: 10,000 EGP
      expect(provider.currentTreasuryBalance, equals(10000.0));
      expect(provider.getTreasuryBalanceForMonth('2026-11'), equals(10000.0));

      // December: New month starts
      await provider.setSelectedMonth('2026-12');

      // Requirement: Opening balance is 0 automatically, previous 10,000 NOT carried forward
      expect(provider.initialBalance, equals(0.0));
      expect(provider.currentTreasuryBalance, equals(0.0));

      // Manually enter new available treasury amount: 60,000 EGP
      await provider.setPeriodOpeningBalance('2026-12', 60000.0);
      expect(provider.currentTreasuryBalance, equals(60000.0));

      // Check November: historical records preserved, balance still 10,000 EGP
      expect(provider.getTreasuryBalanceForMonth('2026-11'), equals(10000.0));
      await provider.setSelectedMonth('2026-11');
      expect(provider.currentTreasuryBalance, equals(10000.0));

      // Prevents creating duplicate financial periods
      final periodCountBefore = provider.periods.length;
      await provider.ensurePeriodExists('2026-11');
      expect(provider.periods.length, equals(periodCountBefore));
    });
  });

  group('Requirement 3: Adding Money to the Treasury Anytime', () {
    test('Can deposit money anytime with amount, date, description, type, and timestamp', () async {
      final provider = AppProvider();
      await provider.init();

      await provider.setSelectedMonth('2026-11');
      await provider.setPeriodOpeningBalance('2026-11', 50000.0);
      expect(provider.currentTreasuryBalance, equals(50000.0));

      // November 10: Add 10,000 EGP
      final dateNov10 = DateTime(2026, 11, 10, 14, 30);
      await provider.addTreasuryDeposit(
        amount: 10000.0,
        date: dateNov10,
        reason: 'دعم مالي إضافي من الإدارة',
        month: '2026-11',
      );
      expect(provider.currentTreasuryBalance, equals(60000.0));

      // November 20: Add another 5,000 EGP
      final dateNov20 = DateTime(2026, 11, 20, 11, 15);
      await provider.addTreasuryDeposit(
        amount: 5000.0,
        date: dateNov20,
        reason: 'توريد نقدية من المبيعات',
        month: '2026-11',
      );
      expect(provider.currentTreasuryBalance, equals(65000.0));

      // Verify transaction details
      final tx = provider.transactions.firstWhere((t) => t.amount == 5000.0);
      expect(tx.amount, equals(5000.0));
      expect(tx.date, equals(dateNov20));
      expect(tx.notes, equals('توريد نقدية من المبيعات'));
      expect(tx.type, equals(TransactionType.deposit));
      expect(tx.isCredit, isTrue);
      expect(tx.createdAt, isNotNull);
    });
  });

  group('Requirement 4: Monthly Employee Salaries & Independent Records', () {
    test('Monthly salaries are independent, track paid/partially paid/unpaid, and deduct from treasury', () async {
      final provider = AppProvider();
      await provider.init();

      // Setup employee with master basic salary = 8000
      final emp = Employee(
        id: 'emp_1',
        name: 'أحمد محمود',
        phone: '01012345678',
        salary: 8000.0,
      );
      await provider.addEmployee(emp);

      // Start November with 50,000 in treasury
      await provider.setSelectedMonth('2026-11');
      await provider.setPeriodOpeningBalance('2026-11', 50000.0);

      // Set November salary record manually
      await provider.setEmployeeMonthlySalary(
        employeeId: emp.id,
        month: '2026-11',
        basicSalary: 8000.0,
        additions: 500.0,
        deductions: 200.0,
      );

      final recNov = provider.getEmployeeSalaryRecord(emp.id, '2026-11');
      expect(recNov, isNotNull);
      expect(recNov!.netSalary, equals(8300.0));
      expect(recNov.isUnpaid, isTrue);

      // Pay partially: 5,000 EGP
      await provider.paySalary(
        salary: recNov,
        paymentAmount: 5000.0,
        paymentDate: DateTime(2026, 11, 28),
        paymentMethod: 'كاش',
        notes: 'دفعة أولى من المرتب',
      );

      final recNovAfterPart = provider.getEmployeeSalaryRecord(emp.id, '2026-11');
      expect(recNovAfterPart!.paidAmount, equals(5000.0));
      expect(recNovAfterPart.remainingUnpaidSalary, equals(3300.0));
      expect(recNovAfterPart.isPartiallyPaid, isTrue);
      expect(provider.currentTreasuryBalance, equals(45000.0)); // 50000 - 5000

      // Pay remaining: 3,300 EGP
      await provider.paySalary(
        salary: recNovAfterPart,
        paymentAmount: 3300.0,
        paymentDate: DateTime(2026, 11, 30),
        paymentMethod: 'كاش',
      );

      final recNovFinal = provider.getEmployeeSalaryRecord(emp.id, '2026-11');
      expect(recNovFinal!.isFullyPaid, isTrue);
      expect(recNovFinal.paidAmount, equals(8300.0));
      expect(recNovFinal.remainingUnpaidSalary, equals(0.0));
      expect(recNovFinal.payments.length, equals(2));
      expect(provider.currentTreasuryBalance, equals(41700.0)); // 45000 - 3300
    });
  });

  group('Requirement 5: Monthly Employee Advances – Reset to Zero', () {
    test('Advances are completely independent per month, reset to zero in new month, and do not affect next month', () async {
      final provider = AppProvider();
      await provider.init();

      final emp = Employee(
        id: 'emp_ahmed',
        name: 'أحمد محمد',
        phone: '01099999999',
        salary: 8000.0,
      );
      await provider.addEmployee(emp);

      // --- NOVEMBER ---
      await provider.setSelectedMonth('2026-11');
      await provider.setPeriodOpeningBalance('2026-11', 50000.0);

      // Ahmed takes advance: 2,000 in November
      await provider.addAdvance(
        Advance(
          id: 'adv_nov_1',
          employeeId: emp.id,
          employeeName: emp.name,
          amount: 2000.0,
          date: DateTime(2026, 11, 5),
          month: '2026-11',
        ),
      );
      expect(provider.getEmployeeRemainingAdvances(emp.id, month: '2026-11'), equals(2000.0));
      expect(provider.currentTreasuryBalance, equals(48000.0)); // 50,000 - 2,000

      // November salary with advance deduction: 8,000 - 2,000 = 6,000
      await provider.setEmployeeMonthlySalary(
        employeeId: emp.id,
        month: '2026-11',
        basicSalary: 8000.0,
        advancesDeducted: 2000.0,
      );
      final novSalary = provider.getEmployeeSalaryRecord(emp.id, '2026-11')!;
      expect(novSalary.netSalary, equals(6000.0));

      await provider.paySalary(salary: novSalary);
      expect(provider.getEmployeeRemainingAdvances(emp.id, month: '2026-11'), equals(0.0));

      // --- DECEMBER ---
      await provider.setSelectedMonth('2026-12');

      // Requirement: Monthly advances start from zero automatically in December!
      expect(provider.getEmployeeRemainingAdvances(emp.id, month: '2026-12'), equals(0.0));
      expect(provider.advancesForSelectedMonth.length, equals(0));

      // Ahmed takes a new advance of 1,000 in December
      await provider.addAdvance(
        Advance(
          id: 'adv_dec_1',
          employeeId: emp.id,
          employeeName: emp.name,
          amount: 1000.0,
          date: DateTime(2026, 12, 4),
          month: '2026-12',
        ),
      );
      expect(provider.getEmployeeRemainingAdvances(emp.id, month: '2026-12'), equals(1000.0));

      // December salary: 8,000 - 1,000 advance = 7,000
      await provider.setEmployeeMonthlySalary(
        employeeId: emp.id,
        month: '2026-12',
        basicSalary: 8000.0,
        advancesDeducted: 1000.0,
      );
      final decSalary = provider.getEmployeeSalaryRecord(emp.id, '2026-12')!;
      expect(decSalary.netSalary, equals(7000.0));

      // Previous month's advance does NOT affect December's monthly calculations
      expect(provider.getEmployeeRemainingAdvances(emp.id, month: '2026-12'), equals(1000.0));
      // Historical advances in November remain preserved
      expect(provider.getEmployeeAdvancesForMonth(emp.id, '2026-11').length, equals(1));
    });
  });

  group('Requirement 6: Advance Settlement, Exceptional Cases & Audit Corrections', () {
    test('Exceptional cases support outstanding advances, corrections with audit log, and never auto-carry into next month', () async {
      final provider = AppProvider();
      await provider.init();

      final emp = Employee(
        id: 'emp_ex',
        name: 'محمود حسن',
        phone: '01122334455',
        salary: 7000.0,
      );
      await provider.addEmployee(emp);

      await provider.setSelectedMonth('2026-11');
      await provider.setPeriodOpeningBalance('2026-11', 30000.0);

      // Advance of 1,500 given in November
      final adv = Advance(
        id: 'adv_ex_1',
        employeeId: emp.id,
        employeeName: emp.name,
        amount: 1500.0,
        date: DateTime(2026, 11, 8),
        month: '2026-11',
      );
      await provider.addAdvance(adv);

      // Advance was NOT deducted from salary -> mark as outstanding
      await provider.markAdvanceAsOutstanding(
        adv.id,
        reason: 'تعذر الخصم هذا الشهر بسبب التزامات العامل العائلية',
      );

      final updatedAdv = provider.advances.firstWhere((a) => a.id == adv.id);
      expect(updatedAdv.isOutstanding, isTrue);
      expect(updatedAdv.statusNotes, contains('تعذر الخصم'));

      // Check Exceptional Cases Summary for November
      final summaryNov = provider.getExceptionalCasesSummary('2026-11');
      expect((summaryNov['outstandingAdvances'] as List).length, equals(1));

      // In December: Next month's advances MUST still start from zero!
      await provider.setSelectedMonth('2026-12');
      expect(provider.getEmployeeRemainingAdvances(emp.id, month: '2026-12'), equals(0.0));

      // The outstanding advance is preserved as a historical outstanding record
      expect(provider.getEmployeeOutstandingHistoricalAdvances(emp.id), equals(1500.0));

      // Audit correction test:
      await provider.setEmployeeMonthlySalary(
        employeeId: emp.id,
        month: '2026-12',
        basicSalary: 7000.0,
        deductions: 500.0,
      );
      final recDec = provider.getEmployeeSalaryRecord(emp.id, '2026-12')!;

      // Correction of deduction from 500 to 100 with audit note
      await provider.recordSalaryCorrection(
        recordId: recDec.id,
        newBasicSalary: 7000.0,
        newAdditions: 0.0,
        newDeductions: 100.0,
        newAdvancesDeducted: 0.0,
        auditReason: 'تصحيح خطأ إملائي في قيمة الخصم المسجل',
      );

      final correctedRec = provider.getEmployeeSalaryRecord(emp.id, '2026-12')!;
      expect(correctedRec.deductions, equals(100.0));
      expect(correctedRec.netSalary, equals(6900.0));
      expect(correctedRec.auditLog.length, equals(1));
      expect(correctedRec.auditLog.first.details, contains('تصحيح خطأ'));
    });
  });
}
