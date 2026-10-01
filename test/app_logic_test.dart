import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:employee/providers/app_provider.dart';
import 'package:employee/models/income.dart';
import 'package:employee/models/expense.dart';
import 'package:employee/models/salary_record.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Seed data matches exact user specifications', () async {
    final provider = AppProvider();
    await provider.init();

    // 1. Employee count = 25
    expect(provider.totalEmployeesCount, equals(25));
    expect(provider.employees.length, equals(25));

    // 2. Financial Figures:
    // Treasury = 125,000 ج.م
    expect(provider.currentTreasuryBalance, equals(125000.0));
    // Income = 80,000 ج.م
    expect(provider.totalIncomeForSelectedMonth, equals(80000.0));
    // Expense = 45,000 ج.م
    expect(provider.totalExpenseForSelectedMonth, equals(45000.0));
    // September Salaries = 32,000 ج.م
    expect(provider.totalPaidSalariesForSelectedMonth, equals(32000.0));

    // 3. Payroll Status:
    // Paid = 18, Unpaid = 7
    expect(provider.paidEmployeesCountForSelectedMonth, equals(18));
    expect(provider.unpaidEmployeesCountForSelectedMonth, equals(7));

    // 4. Alert message verification
    expect(provider.unpaidEmployeesForSelectedMonth.length, equals(7));

    // 5. Operations log has transactions
    expect(provider.transactions.isNotEmpty, isTrue);

    // 6. Test Ahmed Mohamed data
    final ahmed = provider.employees.firstWhere((e) => e.name.contains('أحمد محمد'));
    expect(ahmed.salary, equals(8000.0));
    expect(provider.getEmployeeRemainingAdvances(ahmed.id), equals(2000.0));

    final lastSalary = provider.getEmployeeLastPaidSalary(ahmed.id);
    expect(lastSalary, isNotNull);
    expect(lastSalary!.netSalary, equals(8000.0));
  });

  test('Treasury operations: Income, Expense, Salary Payment', () async {
    final provider = AppProvider();
    await provider.init();

    final initialBalance = provider.currentTreasuryBalance; // 125,000

    // Test Adding Income: +10,000
    await provider.addIncome(
      Income(
        id: 'inc_test_1',
        amount: 10000.0,
        reason: 'مبيعات نقدية إضافية',
        date: DateTime.now(),
        notes: 'تجربة',
      ),
    );
    expect(provider.currentTreasuryBalance, equals(initialBalance + 10000.0));

    // Test Adding Expense: -5,000
    final balanceAfterIncome = provider.currentTreasuryBalance;
    await provider.addExpense(
      Expense(
        id: 'exp_test_1',
        amount: 5000.0,
        category: 'صيانة',
        description: 'صيانة دورية',
        date: DateTime.now(),
        notes: 'تجربة',
      ),
    );
    expect(provider.currentTreasuryBalance, equals(balanceAfterIncome - 5000.0));

    // Test Paying Salary for one of the unpaid employees
    final unpaidEmployee = provider.unpaidEmployeesForSelectedMonth.first;
    final balanceBeforeSalary = provider.currentTreasuryBalance;
    final salary = unpaidEmployee.salary;

    await provider.paySalary(
      SalaryRecord(
        id: 'sal_test_1',
        employeeId: unpaidEmployee.id,
        employeeName: unpaidEmployee.name,
        month: '2026-09',
        basicSalary: salary,
        additions: 0,
        deductions: 0,
        advancesDeducted: 0,
        isPaid: true,
        paymentMethod: 'كاش',
        paymentDate: DateTime.now(),
      ),
    );

    // Treasury reduced by salary amount
    expect(provider.currentTreasuryBalance, equals(balanceBeforeSalary - salary));
    // Paid count increased by 1, unpaid decreased by 1
    expect(provider.paidEmployeesCountForSelectedMonth, equals(19));
    expect(provider.unpaidEmployeesCountForSelectedMonth, equals(6));
  });
}
