import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/advance.dart';
import '../models/salary_record.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/treasury_transaction.dart';
import '../services/storage_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<Employee> _employees = [];
  List<Advance> _advances = [];
  List<SalaryRecord> _salaries = [];
  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  List<TreasuryTransaction> _transactions = [];
  double _initialBalance = 0.0;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  bool _isLoading = true;

  AppProvider() {
    init();
  }

  bool get isLoading => _isLoading;
  List<Employee> get employees => _employees;
  List<Advance> get advances => _advances;
  List<SalaryRecord> get salaries => _salaries;
  List<Income> get incomes => _incomes;
  List<Expense> get expenses => _expenses;
  List<TreasuryTransaction> get transactions => _transactions;
  double get initialBalance => _initialBalance;
  String get selectedMonth => _selectedMonth;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final hasCleaned = await _storageService.hasCleanedStaticData();
    if (!hasCleaned) {
      await _storageService.clearAll();
      await _storageService.markStaticDataCleaned();
    }

    _initialBalance = await _storageService.getInitialBalance();
    _employees = await _storageService.getEmployees();
    _advances = await _storageService.getAdvances();
    _salaries = await _storageService.getSalaries();
    _incomes = await _storageService.getIncomes();
    _expenses = await _storageService.getExpenses();
    _transactions = await _storageService.getTransactions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> resetToSeedData() async {
    await clearAllData();
  }

  Future<void> clearAllData() async {
    await _storageService.clearAll();
    _initialBalance = 0.0;
    _employees = [];
    _advances = [];
    _salaries = [];
    _incomes = [];
    _expenses = [];
    _transactions = [];
    await _saveAll();
    await _storageService.setInitialized(true);
    notifyListeners();
  }

  Future<void> _saveAll() async {
    await _storageService.saveInitialBalance(_initialBalance);
    await _storageService.saveEmployees(_employees);
    await _storageService.saveAdvances(_advances);
    await _storageService.saveSalaries(_salaries);
    await _storageService.saveIncomes(_incomes);
    await _storageService.saveExpenses(_expenses);
    await _storageService.saveTransactions(_transactions);
  }

  double get currentTreasuryBalance {
    final movement = _transactions.fold<double>(
      0.0,
      (sum, t) => sum + (t.isCredit ? t.amount : -t.amount),
    );
    return _initialBalance + movement;
  }

  double get totalIncomeForSelectedMonth {
    final format = DateFormat('yyyy-MM');
    return _incomes
        .where((inc) => format.format(inc.date) == _selectedMonth)
        .fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  double get totalIncomeAllTime {
    return _incomes.fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpenseForSelectedMonth {
    final format = DateFormat('yyyy-MM');
    return _expenses
        .where((exp) => format.format(exp.date) == _selectedMonth)
        .fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpenseAllTime {
    return _expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  double get totalPaidSalariesForSelectedMonth {
    return _salaries
        .where((sal) => sal.month == _selectedMonth && sal.isPaid)
        .fold<double>(0.0, (sum, item) => sum + item.netSalary);
  }

  double get totalUnpaidSalariesForSelectedMonth {
    return unpaidEmployeesForSelectedMonth.fold<double>(
      0.0,
      (sum, emp) => sum + emp.salary,
    );
  }

  int get totalEmployeesCount => _employees.length;
  int get activeEmployeesCount => _employees.where((e) => e.isActive).length;

  int get paidEmployeesCountForSelectedMonth {
    return _salaries
        .where((sal) => sal.month == _selectedMonth && sal.isPaid)
        .length;
  }

  int get unpaidEmployeesCountForSelectedMonth {
    return unpaidEmployeesForSelectedMonth.length;
  }

  List<Employee> get unpaidEmployeesForSelectedMonth {
    final paidEmpIds = _salaries
        .where((sal) => sal.month == _selectedMonth && sal.isPaid)
        .map((sal) => sal.employeeId)
        .toSet();

    return _employees
        .where((e) => e.isActive && !paidEmpIds.contains(e.id))
        .toList();
  }

  double getEmployeeRemainingAdvances(String employeeId) {
    return _advances
        .where((a) => a.employeeId == employeeId)
        .fold<double>(0.0, (sum, a) => sum + a.remainingAmount);
  }

  List<Advance> getEmployeeActiveAdvances(String employeeId) {
    return _advances
        .where((a) => a.employeeId == employeeId && a.remainingAmount > 0)
        .toList();
  }

  SalaryRecord? getEmployeeSalaryRecord(String employeeId, String month) {
    try {
      return _salaries.firstWhere(
        (sal) => sal.employeeId == employeeId && sal.month == month,
      );
    } catch (_) {
      return null;
    }
  }

  SalaryRecord? getEmployeeLastPaidSalary(String employeeId) {
    final paidList = _salaries
        .where((sal) => sal.employeeId == employeeId && sal.isPaid)
        .toList();
    if (paidList.isEmpty) return null;
    paidList.sort((a, b) => (b.paymentDate ?? DateTime(2000))
        .compareTo(a.paymentDate ?? DateTime(2000)));
    return paidList.first;
  }

  double getEmployeeTotalPaid(String employeeId) {
    final totalSalary = _salaries
        .where((sal) => sal.employeeId == employeeId && sal.isPaid)
        .fold<double>(0.0, (sum, sal) => sum + sal.netSalary);
    final totalAdv = _advances
        .where((a) => a.employeeId == employeeId)
        .fold<double>(0.0, (sum, a) => sum + a.amount);
    return totalSalary + totalAdv;
  }

  List<Advance> getEmployeeAdvances(String employeeId) {
    return _advances.where((a) => a.employeeId == employeeId).toList();
  }

  List<SalaryRecord> getEmployeeSalaries(String employeeId) {
    return _salaries.where((s) => s.employeeId == employeeId).toList();
  }

  Employee? getEmployeeById(String id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addEmployee(Employee employee) async {
    _employees.add(employee);
    await _storageService.saveEmployees(_employees);
    notifyListeners();
  }

  Future<void> updateEmployee(Employee employee) async {
    final idx = _employees.indexWhere((e) => e.id == employee.id);
    if (idx != -1) {
      _employees[idx] = employee;
      await _storageService.saveEmployees(_employees);
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(String id) async {
    _employees.removeWhere((e) => e.id == id);
    await _storageService.saveEmployees(_employees);
    notifyListeners();
  }

  Future<void> toggleEmployeeStatus(String id) async {
    final idx = _employees.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final current = _employees[idx];
      _employees[idx] = current.copyWith(isActive: !current.isActive);
      await _storageService.saveEmployees(_employees);
      notifyListeners();
    }
  }

  Future<void> addIncome(Income income) async {
    _incomes.insert(0, income);
    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_inc',
      date: income.date,
      type: TransactionType.income,
      amount: income.amount,
      isCredit: true,
      title: 'وارد: ${income.reason}',
      notes: income.notes,
      referenceId: income.id,
    );
    _transactions.insert(0, tx);

    await _storageService.saveIncomes(_incomes);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((i) => i.id == id);
    _transactions.removeWhere((t) => t.referenceId == id);
    await _storageService.saveIncomes(_incomes);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.insert(0, expense);
    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_exp',
      date: expense.date,
      type: TransactionType.expense,
      amount: expense.amount,
      isCredit: false,
      title: 'مصروف: ${expense.category} - ${expense.description}',
      notes: expense.notes,
      referenceId: expense.id,
    );
    _transactions.insert(0, tx);

    await _storageService.saveExpenses(_expenses);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    _transactions.removeWhere((t) => t.referenceId == id);
    await _storageService.saveExpenses(_expenses);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> addAdvance(Advance advance) async {
    _advances.insert(0, advance);
    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_adv',
      date: advance.date,
      type: TransactionType.advancePayout,
      amount: advance.amount,
      isCredit: false,
      title: 'سلفة: ${advance.employeeName}',
      notes: advance.notes,
      referenceId: advance.id,
    );
    _transactions.insert(0, tx);

    await _storageService.saveAdvances(_advances);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> repayAdvanceDirectly(String advanceId, double repayAmount) async {
    final idx = _advances.indexWhere((a) => a.id == advanceId);
    if (idx != -1) {
      final current = _advances[idx];
      final newPaid = current.paidAmount + repayAmount;
      _advances[idx] = current.copyWith(paidAmount: newPaid);

      final tx = TreasuryTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}_repay',
        date: DateTime.now(),
        type: TransactionType.advanceRepayment,
        amount: repayAmount,
        isCredit: true,
        title: 'سداد سلفة: ${current.employeeName}',
        notes: 'سداد نقدي مباشر لخزينة المؤسسة',
        referenceId: advanceId,
      );
      _transactions.insert(0, tx);

      await _storageService.saveAdvances(_advances);
      await _storageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  Future<void> deleteAdvance(String id) async {
    _advances.removeWhere((a) => a.id == id);
    _transactions.removeWhere((t) => t.referenceId == id);
    await _storageService.saveAdvances(_advances);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> paySalary(SalaryRecord salary) async {
    final idx = _salaries.indexWhere(
      (s) => s.employeeId == salary.employeeId && s.month == salary.month,
    );

    SalaryRecord updatedRecord = salary.copyWith(
      isPaid: true,
      paymentDate: salary.paymentDate ?? DateTime.now(),
    );

    if (idx != -1) {
      _salaries[idx] = updatedRecord;
    } else {
      _salaries.insert(0, updatedRecord);
    }

    if (salary.advancesDeducted > 0) {
      double remainingToDeduct = salary.advancesDeducted;
      for (int i = 0; i < _advances.length; i++) {
        if (_advances[i].employeeId == salary.employeeId &&
            _advances[i].remainingAmount > 0) {
          final adv = _advances[i];
          final canDeduct = adv.remainingAmount;
          if (remainingToDeduct <= canDeduct) {
            _advances[i] = adv.copyWith(paidAmount: adv.paidAmount + remainingToDeduct);
            remainingToDeduct = 0;
            break;
          } else {
            _advances[i] = adv.copyWith(paidAmount: adv.amount);
            remainingToDeduct -= canDeduct;
          }
        }
      }
      await _storageService.saveAdvances(_advances);
    }

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_sal',
      date: updatedRecord.paymentDate ?? DateTime.now(),
      type: TransactionType.salary,
      amount: updatedRecord.netSalary,
      isCredit: false,
      title: 'مرتب: ${updatedRecord.employeeName} (شهر ${updatedRecord.month})',
      notes: updatedRecord.notes.isNotEmpty
          ? updatedRecord.notes
          : 'صرف مرتب ${updatedRecord.paymentMethod}',
      referenceId: updatedRecord.id,
    );
    _transactions.insert(0, tx);

    await _storageService.saveSalaries(_salaries);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> saveUnpaidSalaryRecord(SalaryRecord salary) async {
    final idx = _salaries.indexWhere(
      (s) => s.employeeId == salary.employeeId && s.month == salary.month,
    );
    if (idx != -1) {
      _salaries[idx] = salary;
    } else {
      _salaries.insert(0, salary);
    }
    await _storageService.saveSalaries(_salaries);
    notifyListeners();
  }

  Future<void> adjustTreasuryBalance(double newBalance, String reason) async {
    final current = currentTreasuryBalance;
    final diff = newBalance - current;
    if (diff == 0) return;

    final isCredit = diff > 0;
    final absAmount = diff.abs();

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_adj',
      date: DateTime.now(),
      type: TransactionType.adjustment,
      amount: absAmount,
      isCredit: isCredit,
      title: isCredit ? 'تسوية زيادة في الخزنة' : 'تسوية عجز/سحب من الخزنة',
      notes: reason.isNotEmpty ? reason : 'تعديل رصيد الخزنة يدوياً',
    );
    _transactions.insert(0, tx);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> manualTreasuryMovement({
    required double amount,
    required bool isCredit,
    required String reason,
  }) async {
    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_man',
      date: DateTime.now(),
      type: TransactionType.adjustment,
      amount: amount,
      isCredit: isCredit,
      title: isCredit ? 'إيداع نقدي بالخزنة: $reason' : 'سحب نقدي من الخزنة: $reason',
      notes: reason,
    );
    _transactions.insert(0, tx);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<int> payAllUnpaidSalaries({
    required String month,
    bool autoDeductAdvances = true,
  }) async {
    final unpaid = unpaidEmployeesForSelectedMonth;
    if (unpaid.isEmpty) return 0;

    final now = DateTime.now();
    int count = 0;

    for (final emp in unpaid) {
      final existingRecord = getEmployeeSalaryRecord(emp.id, month);

      double advanceDeduct = 0.0;
      if (autoDeductAdvances) {
        final remAdv = getEmployeeRemainingAdvances(emp.id);
        advanceDeduct = remAdv > emp.salary ? emp.salary : remAdv;
      }

      final basic = existingRecord?.basicSalary ?? emp.salary;
      final additions = existingRecord?.additions ?? 0.0;
      final deductions = existingRecord?.deductions ?? 0.0;
      final finalAdvanceDeduct = (existingRecord != null && existingRecord.advancesDeducted > 0)
          ? existingRecord.advancesDeducted
          : advanceDeduct;

      final netSalary = (basic + additions - deductions - finalAdvanceDeduct);

      final updatedRecord = SalaryRecord(
        id: existingRecord?.id ?? 'sal_${emp.id}_$month',
        employeeId: emp.id,
        employeeName: emp.name,
        month: month,
        basicSalary: basic,
        additions: additions,
        deductions: deductions,
        advancesDeducted: finalAdvanceDeduct,
        isPaid: true,
        paymentMethod: 'كاش',
        paymentDate: now,
        notes: 'صرف جماعي لكافة المرتبات المستحقة نقداً',
      );

      final idx = _salaries.indexWhere(
        (s) => s.employeeId == emp.id && s.month == month,
      );
      if (idx != -1) {
        _salaries[idx] = updatedRecord;
      } else {
        _salaries.insert(0, updatedRecord);
      }

      if (finalAdvanceDeduct > 0) {
        double remToDeduct = finalAdvanceDeduct;
        for (int i = 0; i < _advances.length; i++) {
          if (_advances[i].employeeId == emp.id && _advances[i].remainingAmount > 0) {
            final adv = _advances[i];
            final canDeduct = adv.remainingAmount;
            if (remToDeduct <= canDeduct) {
              _advances[i] = adv.copyWith(paidAmount: adv.paidAmount + remToDeduct);
              remToDeduct = 0;
              break;
            } else {
              _advances[i] = adv.copyWith(paidAmount: adv.amount);
              remToDeduct -= canDeduct;
            }
          }
        }
      }

      final tx = TreasuryTransaction(
        id: 'tx_${now.millisecondsSinceEpoch}_${emp.id}_sal',
        date: now,
        type: TransactionType.salary,
        amount: netSalary,
        isCredit: false,
        title: 'مرتب: ${emp.name} (شهر $month)',
        notes: finalAdvanceDeduct > 0
            ? 'صرف كاش بعد خصم سلفة مسجلة (${finalAdvanceDeduct.toStringAsFixed(0)} ج)'
            : 'صرف كاش بالكامل',
        referenceId: updatedRecord.id,
      );
      _transactions.insert(0, tx);
      count++;
    }

    await _storageService.saveSalaries(_salaries);
    await _storageService.saveAdvances(_advances);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
    return count;
  }
}
