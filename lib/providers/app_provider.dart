import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/advance.dart';
import '../models/salary_record.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/treasury_transaction.dart';
import '../models/monthly_period.dart';
import '../services/storage_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<MonthlyPeriod> _periods = [];
  List<Employee> _employees = [];
  List<Advance> _advances = [];
  List<SalaryRecord> _salaries = [];
  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  List<TreasuryTransaction> _transactions = [];
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  bool _isLoading = true;

  AppProvider() {
    init();
  }

  bool get isLoading => _isLoading;
  List<MonthlyPeriod> get periods => _periods;
  List<Employee> get employees => _employees;
  List<Advance> get advances => _advances;
  List<SalaryRecord> get salaries => _salaries;
  List<Income> get incomes => _incomes;
  List<Expense> get expenses => _expenses;
  List<TreasuryTransaction> get transactions => _transactions;
  String get selectedMonth => _selectedMonth;

  MonthlyPeriod? get currentPeriod => getPeriodForMonth(_selectedMonth);

  MonthlyPeriod? getPeriodForMonth(String month) {
    try {
      return _periods.firstWhere((p) => p.month == month);
    } catch (_) {
      return null;
    }
  }

  /// Sets the selected financial month. If the period does not exist yet,
  /// it is created with 0 opening balance so each month starts clean.
  Future<void> setSelectedMonth(String month) async {
    _selectedMonth = month;
    await ensurePeriodExists(month);
    notifyListeners();
  }

  /// Ensures a financial period exists for [month] without creating duplicates.
  Future<MonthlyPeriod> ensurePeriodExists(
    String month, {
    double openingBalance = 0.0,
  }) async {
    final existing = getPeriodForMonth(month);
    if (existing != null) return existing;

    final newPeriod = MonthlyPeriod(
      month: month,
      openingBalance: openingBalance,
      createdAt: DateTime.now(),
    );
    _periods.add(newPeriod);
    _periods.sort((a, b) => b.month.compareTo(a.month));
    await _storageService.savePeriods(_periods);
    return newPeriod;
  }

  /// Sets or updates the opening balance for a specific month.
  Future<void> setPeriodOpeningBalance(String month, double balance) async {
    await ensurePeriodExists(month);
    final idx = _periods.indexWhere((p) => p.month == month);
    if (idx != -1) {
      _periods[idx] = _periods[idx].copyWith(openingBalance: balance);
      await _storageService.savePeriods(_periods);
      notifyListeners();
    }
  }

  /// Closes a financial period with audit timestamp and optional closing notes.
  Future<void> closePeriod(String month, {String notes = ''}) async {
    final idx = _periods.indexWhere((p) => p.month == month);
    if (idx != -1) {
      _periods[idx] = _periods[idx].copyWith(
        isClosed: true,
        closedAt: DateTime.now(),
        notes: notes,
      );
      await _storageService.savePeriods(_periods);
      notifyListeners();
    }
  }

  /// Reopens a closed financial period.
  Future<void> reopenPeriod(String month) async {
    final idx = _periods.indexWhere((p) => p.month == month);
    if (idx != -1) {
      _periods[idx] = _periods[idx].copyWith(
        isClosed: false,
        closedAt: null,
      );
      await _storageService.savePeriods(_periods);
      notifyListeners();
    }
  }

  /// Returns all available months in the system, sorted descending (newest first).
  List<String> get availableMonths {
    final set = <String>{_selectedMonth};
    for (final p in _periods) {
      set.add(p.month);
    }
    for (final s in _salaries) {
      set.add(s.month);
    }
    for (final a in _advances) {
      set.add(a.month);
    }
    for (final t in _transactions) {
      set.add(t.month);
    }
    for (final i in _incomes) {
      set.add(DateFormat('yyyy-MM').format(i.date));
    }
    for (final e in _expenses) {
      set.add(DateFormat('yyyy-MM').format(e.date));
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _periods = await _storageService.getPeriods();
    _employees = await _storageService.getEmployees();
    _advances = await _storageService.getAdvances();
    _salaries = await _storageService.getSalaries();
    _incomes = await _storageService.getIncomes();
    _expenses = await _storageService.getExpenses();
    _transactions = await _storageService.getTransactions();

    // Ensure period exists for current selected month
    await ensurePeriodExists(_selectedMonth);

    // If initialBalance from legacy exists and there are no periods, initialize period
    if (_periods.isEmpty) {
      final legacyInitial = await _storageService.getInitialBalance();
      if (legacyInitial > 0) {
        await ensurePeriodExists(_selectedMonth, openingBalance: legacyInitial);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _storageService.clearAll();
    _periods = [];
    _employees = [];
    _advances = [];
    _salaries = [];
    _incomes = [];
    _expenses = [];
    _transactions = [];
    await ensurePeriodExists(_selectedMonth);
    notifyListeners();
  }

  Future<void> resetToSeedData() async {
    await clearAllData();
  }

  // -------------------------------------------------------------
  // TREASURY CALCULATIONS (Independent per Month)
  // -------------------------------------------------------------

  /// Calculates treasury balance for a specific month.
  /// Starts at 0.0 unless manually given an opening balance for that month.
  /// Never carries over balances from prior months.
  double getTreasuryBalanceForMonth(String month) {
    final period = getPeriodForMonth(month);
    final opening = period?.openingBalance ?? 0.0;
    final txs = _transactions.where((t) => t.month == month);
    final movement = txs.fold<double>(
      0.0,
      (sum, t) => sum + (t.isCredit ? t.amount : -t.amount),
    );
    return opening + movement;
  }

  /// Opening balance for the currently selected month.
  double get initialBalance =>
      getPeriodForMonth(_selectedMonth)?.openingBalance ?? 0.0;

  /// Current month's treasury balance.
  double get currentTreasuryBalance =>
      getTreasuryBalanceForMonth(_selectedMonth);

  /// Transactions belonging to the currently selected month.
  List<TreasuryTransaction> get transactionsForSelectedMonth =>
      _transactions.where((t) => t.month == _selectedMonth).toList();

  /// Total deposits added to the treasury for the selected month.
  double get totalDepositsForSelectedMonth {
    return _transactions
        .where((t) =>
            t.month == _selectedMonth && t.type == TransactionType.deposit)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Add money to treasury at any time (Requirement #3).
  Future<void> addTreasuryDeposit({
    required double amount,
    required DateTime date,
    required String reason,
    String? month,
  }) async {
    final targetMonth = month ?? DateFormat('yyyy-MM').format(date);
    await ensurePeriodExists(targetMonth);

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_dep',
      date: date,
      month: targetMonth,
      type: TransactionType.deposit,
      amount: amount,
      isCredit: true,
      title: 'إيداع نقدي بالخزنة: $reason',
      notes: reason,
      createdAt: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  /// Withdraw money from treasury.
  Future<void> addTreasuryWithdrawal({
    required double amount,
    required DateTime date,
    required String reason,
    String? month,
  }) async {
    final targetMonth = month ?? DateFormat('yyyy-MM').format(date);
    await ensurePeriodExists(targetMonth);

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_wth',
      date: date,
      month: targetMonth,
      type: TransactionType.withdrawal,
      amount: amount,
      isCredit: false,
      title: 'سحب نقدي من الخزنة: $reason',
      notes: reason,
      createdAt: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  /// Manual adjustment of treasury balance for a specific month.
  Future<void> adjustTreasuryBalance(
    double newBalance,
    String reason, {
    String? month,
  }) async {
    final targetMonth = month ?? _selectedMonth;
    final current = getTreasuryBalanceForMonth(targetMonth);
    final diff = newBalance - current;
    if (diff == 0) return;

    final isCredit = diff > 0;
    final absAmount = diff.abs();

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_adj',
      date: DateTime.now(),
      month: targetMonth,
      type: TransactionType.adjustment,
      amount: absAmount,
      isCredit: isCredit,
      title: isCredit ? 'تسوية زيادة في الخزنة' : 'تسوية عجز/سحب من الخزنة',
      notes: reason.isNotEmpty ? reason : 'تعديل رصيد الخزنة يدوياً',
      createdAt: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  /// Direct manual movement.
  Future<void> manualTreasuryMovement({
    required double amount,
    required bool isCredit,
    required String reason,
    String? month,
    DateTime? date,
  }) async {
    final txDate = date ?? DateTime.now();
    final targetMonth = month ?? _selectedMonth;
    await ensurePeriodExists(targetMonth);

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_man',
      date: txDate,
      month: targetMonth,
      type: isCredit ? TransactionType.deposit : TransactionType.withdrawal,
      amount: amount,
      isCredit: isCredit,
      title: isCredit
          ? 'إيداع نقدي بالخزنة: $reason'
          : 'سحب نقدي من الخزنة: $reason',
      notes: reason,
      createdAt: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // INCOME & EXPENSES
  // -------------------------------------------------------------

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

  Future<void> addIncome(Income income) async {
    _incomes.insert(0, income);
    final month = DateFormat('yyyy-MM').format(income.date);
    await ensurePeriodExists(month);

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_inc',
      date: income.date,
      month: month,
      type: TransactionType.income,
      amount: income.amount,
      isCredit: true,
      title: 'وارد: ${income.reason}',
      notes: income.notes,
      referenceId: income.id,
      createdAt: DateTime.now(),
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
    final month = DateFormat('yyyy-MM').format(expense.date);
    await ensurePeriodExists(month);

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_exp',
      date: expense.date,
      month: month,
      type: TransactionType.expense,
      amount: expense.amount,
      isCredit: false,
      title: 'مصروف: ${expense.category} - ${expense.description}',
      notes: expense.notes,
      referenceId: expense.id,
      createdAt: DateTime.now(),
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

  // -------------------------------------------------------------
  // EMPLOYEES
  // -------------------------------------------------------------

  int get totalEmployeesCount => _employees.length;
  int get activeEmployeesCount => _employees.where((e) => e.isActive).length;

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

  // -------------------------------------------------------------
  // ADVANCES (Independent per Month – Reset to Zero in Every New Month)
  // -------------------------------------------------------------

  /// Advances belonging strictly to the currently selected month.
  List<Advance> get advancesForSelectedMonth =>
      _advances.where((a) => a.month == _selectedMonth).toList();

  /// Advances for a specific employee in a specific month.
  List<Advance> getEmployeeAdvancesForMonth(String employeeId, String month) {
    return _advances
        .where((a) => a.employeeId == employeeId && a.month == month)
        .toList();
  }

  /// All historical advances for an employee across all time.
  List<Advance> getEmployeeAdvances(String employeeId) {
    return _advances.where((a) => a.employeeId == employeeId).toList();
  }

  /// Active advances for an employee in the selected month (starts at 0 in new month).
  List<Advance> getEmployeeActiveAdvances(String employeeId, {String? month}) {
    final targetMonth = month ?? _selectedMonth;
    return _advances
        .where((a) =>
            a.employeeId == employeeId &&
            a.month == targetMonth &&
            a.remainingAmount > 0)
        .toList();
  }

  /// Remaining advances for the employee for a given month (defaults to selected month).
  /// Resets to zero automatically at the start of any new month (Requirement #5).
  double getEmployeeRemainingAdvances(String employeeId, {String? month}) {
    final targetMonth = month ?? _selectedMonth;
    return _advances
        .where((a) => a.employeeId == employeeId && a.month == targetMonth)
        .fold<double>(0.0, (sum, a) => sum + a.remainingAmount);
  }

  /// Outstanding/uncollected advances from prior months (kept separate from monthly calculation).
  double getEmployeeOutstandingHistoricalAdvances(
    String employeeId, {
    String? upToMonth,
  }) {
    final targetMonth = upToMonth ?? _selectedMonth;
    return _advances
        .where((a) =>
            a.employeeId == employeeId &&
            a.month.compareTo(targetMonth) < 0 &&
            a.remainingAmount > 0)
        .fold<double>(0.0, (sum, a) => sum + a.remainingAmount);
  }

  /// Records a new advance. Deducts immediately from the current month's treasury.
  Future<void> addAdvance(Advance advance) async {
    final targetMonth = advance.month;
    await ensurePeriodExists(targetMonth);

    _advances.insert(0, advance);

    final tx = TreasuryTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_adv',
      date: advance.date,
      month: targetMonth,
      type: TransactionType.advancePayout,
      amount: advance.amount,
      isCredit: false,
      title: 'سلفة: ${advance.employeeName} (شهر $targetMonth)',
      notes: advance.notes,
      referenceId: advance.id,
      createdAt: DateTime.now(),
    );
    _transactions.insert(0, tx);

    await _storageService.saveAdvances(_advances);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  /// Direct cash repayment of an advance to the treasury.
  Future<void> repayAdvanceDirectly(
    String advanceId,
    double repayAmount, {
    String? notes,
  }) async {
    final idx = _advances.indexWhere((a) => a.id == advanceId);
    if (idx != -1) {
      final current = _advances[idx];
      final newPaid = current.paidAmount + repayAmount;
      _advances[idx] = current.copyWith(paidAmount: newPaid);

      final tx = TreasuryTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}_repay',
        date: DateTime.now(),
        month: _selectedMonth,
        type: TransactionType.advanceRepayment,
        amount: repayAmount,
        isCredit: true,
        title: 'سداد سلفة: ${current.employeeName}',
        notes: notes ?? 'سداد نقدي مباشر لخزينة المؤسسة',
        referenceId: advanceId,
        createdAt: DateTime.now(),
      );
      _transactions.insert(0, tx);

      await _storageService.saveAdvances(_advances);
      await _storageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  /// Mark an advance as outstanding / exceptional without deleting (Requirement #6).
  Future<void> markAdvanceAsOutstanding(
    String advanceId, {
    required String reason,
  }) async {
    final idx = _advances.indexWhere((a) => a.id == advanceId);
    if (idx != -1) {
      _advances[idx] = _advances[idx].copyWith(
        isOutstanding: true,
        statusNotes: reason,
      );
      await _storageService.saveAdvances(_advances);
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

  // -------------------------------------------------------------
  // SALARIES (Independent per Month – Full/Partial/Unpaid tracking)
  // -------------------------------------------------------------

  /// Salary records belonging to the currently selected month.
  List<SalaryRecord> get salariesForSelectedMonth =>
      _salaries.where((s) => s.month == _selectedMonth).toList();

  /// Total actual paid salaries for the selected month.
  double get totalPaidSalariesForSelectedMonth {
    return _salaries
        .where((sal) => sal.month == _selectedMonth)
        .fold<double>(0.0, (sum, item) => sum + item.paidAmount);
  }

  /// Total unpaid salaries for active employees in the selected month.
  double get totalUnpaidSalariesForSelectedMonth {
    double total = 0.0;
    for (final emp in _employees.where((e) => e.isActive)) {
      final rec = getEmployeeSalaryRecord(emp.id, _selectedMonth);
      if (rec != null) {
        total += rec.remainingUnpaidSalary;
      } else {
        total += emp.salary;
      }
    }
    return total;
  }

  int get paidEmployeesCountForSelectedMonth {
    return _employees.where((e) {
      if (!e.isActive) return false;
      final rec = getEmployeeSalaryRecord(e.id, _selectedMonth);
      return rec != null && rec.isFullyPaid;
    }).length;
  }

  int get partiallyPaidEmployeesCountForSelectedMonth {
    return _employees.where((e) {
      if (!e.isActive) return false;
      final rec = getEmployeeSalaryRecord(e.id, _selectedMonth);
      return rec != null && rec.isPartiallyPaid;
    }).length;
  }

  int get unpaidEmployeesCountForSelectedMonth {
    return unpaidEmployeesForSelectedMonth.length;
  }

  /// List of active employees who have unpaid or partially paid salaries for the selected month.
  List<Employee> get unpaidEmployeesForSelectedMonth {
    return _employees.where((e) {
      if (!e.isActive) return false;
      final rec = getEmployeeSalaryRecord(e.id, _selectedMonth);
      if (rec == null) return true;
      return !rec.isFullyPaid;
    }).toList();
  }

  /// Get salary record for a specific employee and month.
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
        .where((sal) => sal.employeeId == employeeId && sal.paidAmount > 0)
        .toList();
    if (paidList.isEmpty) return null;
    paidList.sort((a, b) => (b.paymentDate ?? DateTime(2000))
        .compareTo(a.paymentDate ?? DateTime(2000)));
    return paidList.first;
  }

  List<SalaryRecord> getEmployeeSalaries(String employeeId) {
    return _salaries.where((s) => s.employeeId == employeeId).toList();
  }

  double getEmployeeTotalPaid(String employeeId) {
    final totalSalary = _salaries
        .where((sal) => sal.employeeId == employeeId)
        .fold<double>(0.0, (sum, sal) => sum + sal.paidAmount);
    final totalAdv = _advances
        .where((a) => a.employeeId == employeeId)
        .fold<double>(0.0, (sum, a) => sum + a.amount);
    return totalSalary + totalAdv;
  }

  /// Sets / saves an employee's salary specifications for a specific month (Requirement #4).
  /// Keeps employee's basic salary separate from monthly transactions.
  Future<void> setEmployeeMonthlySalary({
    required String employeeId,
    required String month,
    required double basicSalary,
    double additions = 0.0,
    double deductions = 0.0,
    double advancesDeducted = 0.0,
    String notes = '',
  }) async {
    await ensurePeriodExists(month);
    final emp = getEmployeeById(employeeId);
    final empName = emp?.name ?? 'موظف';

    final existing = getEmployeeSalaryRecord(employeeId, month);
    SalaryRecord record;
    if (existing != null) {
      record = existing.copyWith(
        basicSalary: basicSalary,
        additions: additions,
        deductions: deductions,
        advancesDeducted: advancesDeducted,
        notes: notes.isNotEmpty ? notes : existing.notes,
      );
      final idx = _salaries.indexWhere((s) => s.id == existing.id);
      _salaries[idx] = record;
    } else {
      record = SalaryRecord(
        id: 'sal_${employeeId}_$month',
        employeeId: employeeId,
        employeeName: empName,
        month: month,
        basicSalary: basicSalary,
        additions: additions,
        deductions: deductions,
        advancesDeducted: advancesDeducted,
        notes: notes,
      );
      _salaries.insert(0, record);
    }

    await _storageService.saveSalaries(_salaries);
    notifyListeners();
  }

  /// Pays a salary (full or partial payment).
  /// Deducts the actual payment amount from the current month's treasury immediately.
  Future<void> paySalary({
    required SalaryRecord salary,
    double? paymentAmount,
    DateTime? paymentDate,
    String paymentMethod = 'كاش',
    String notes = '',
    bool autoDeductAdvances = true,
  }) async {
    await ensurePeriodExists(salary.month);
    final date = paymentDate ?? DateTime.now();

    // Actual disbursement amount (cannot exceed net salary - already paid)
    final needed = salary.remainingUnpaidSalary;
    final actualPay = paymentAmount != null
        ? paymentAmount.clamp(0.0, double.infinity)
        : needed;

    final paymentEntry = SalaryPayment(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}_${salary.employeeId}',
      amount: actualPay,
      date: date,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    final updatedPayments = List<SalaryPayment>.from(salary.payments)
      ..add(paymentEntry);
    final totalPaid = salary.paidAmount + actualPay;

    // Deduct advances ONLY belonging to THIS month (Requirement #5)
    if (salary.advancesDeducted > 0 && autoDeductAdvances) {
      double remainingToDeduct = salary.advancesDeducted;
      for (int i = 0; i < _advances.length; i++) {
        if (_advances[i].employeeId == salary.employeeId &&
            _advances[i].month == salary.month && // Strictly this month!
            _advances[i].remainingAmount > 0) {
          final adv = _advances[i];
          final canDeduct = adv.remainingAmount;
          if (remainingToDeduct <= canDeduct) {
            _advances[i] =
                adv.copyWith(paidAmount: adv.paidAmount + remainingToDeduct);
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

    final updatedSalary = salary.copyWith(
      paidAmount: totalPaid,
      payments: updatedPayments,
      paymentDate: date,
      paymentMethod: paymentMethod,
      notes: notes.isNotEmpty ? notes : salary.notes,
    );

    final idx = _salaries.indexWhere(
      (s) => s.employeeId == salary.employeeId && s.month == salary.month,
    );
    if (idx != -1) {
      _salaries[idx] = updatedSalary;
    } else {
      _salaries.insert(0, updatedSalary);
    }

    // Deduct payment amount from month's treasury
    if (actualPay > 0) {
      final tx = TreasuryTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}_sal',
        date: date,
        month: salary.month,
        type: TransactionType.salary,
        amount: actualPay,
        isCredit: false,
        title: 'مرتب: ${salary.employeeName} (شهر ${salary.month})',
        notes: notes.isNotEmpty
            ? notes
            : 'صرف مرتب $paymentMethod ${totalPaid >= salary.netSalary ? "بالكامل" : "جزئياً"}',
        referenceId: updatedSalary.id,
        createdAt: DateTime.now(),
      );
      _transactions.insert(0, tx);
      await _storageService.saveTransactions(_transactions);
    }

    await _storageService.saveSalaries(_salaries);
    notifyListeners();
  }

  /// Saves an unpaid salary record.
  Future<void> saveUnpaidSalaryRecord(SalaryRecord salary) async {
    await ensurePeriodExists(salary.month);
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

  /// Correction of a salary record with audit history (Requirement #6).
  Future<void> recordSalaryCorrection({
    required String recordId,
    required double newBasicSalary,
    required double newAdditions,
    required double newDeductions,
    required double newAdvancesDeducted,
    required String auditReason,
  }) async {
    final idx = _salaries.indexWhere((s) => s.id == recordId);
    if (idx == -1) return;

    final old = _salaries[idx];
    final audit = SalaryAuditEntry(
      timestamp: DateTime.now(),
      action: 'تصحيح وتعديل بيانات المرتب',
      details: auditReason.isNotEmpty
          ? auditReason
          : 'تعديل أساسي: ${old.basicSalary} -> $newBasicSalary، إضافي: ${old.additions} -> $newAdditions، خصم: ${old.deductions} -> $newDeductions',
    );

    final updatedAudit = List<SalaryAuditEntry>.from(old.auditLog)..add(audit);

    _salaries[idx] = old.copyWith(
      basicSalary: newBasicSalary,
      additions: newAdditions,
      deductions: newDeductions,
      advancesDeducted: newAdvancesDeducted,
      auditLog: updatedAudit,
    );

    await _storageService.saveSalaries(_salaries);
    notifyListeners();
  }

  /// Pay all unpaid salaries for [month].
  Future<int> payAllUnpaidSalaries({
    required String month,
    bool autoDeductAdvances = true,
  }) async {
    final unpaid = unpaidEmployeesForSelectedMonth;
    if (unpaid.isEmpty) return 0;

    final now = DateTime.now();
    final salaryDate = getDayOneOfMonth(month);
    int count = 0;

    for (final emp in unpaid) {
      final existingRecord = getEmployeeSalaryRecord(emp.id, month);

      double advanceDeduct = 0.0;
      if (autoDeductAdvances) {
        // Strictly this month's advances!
        final remAdv = getEmployeeRemainingAdvances(emp.id, month: month);
        advanceDeduct = remAdv > emp.salary ? emp.salary : remAdv;
      }

      final basic = existingRecord?.basicSalary ?? emp.salary;
      final additions = existingRecord?.additions ?? 0.0;
      final deductions = existingRecord?.deductions ?? 0.0;
      final finalAdvanceDeduct = (existingRecord != null &&
              existingRecord.advancesDeducted > 0)
          ? existingRecord.advancesDeducted
          : advanceDeduct;

      final netSalary = (basic + additions - deductions - finalAdvanceDeduct);
      final alreadyPaid = existingRecord?.paidAmount ?? 0.0;
      final amountToDisburse =
          (netSalary - alreadyPaid).clamp(0.0, double.infinity);

      if (amountToDisburse <= 0) continue;

      final payment = SalaryPayment(
        id: 'pay_${now.millisecondsSinceEpoch}_${emp.id}',
        amount: amountToDisburse,
        date: salaryDate,
        paymentMethod: 'كاش',
        notes: 'صرف جماعي لكافة المرتبات المستحقة نقداً',
      );

      final updatedPayments =
          List<SalaryPayment>.from(existingRecord?.payments ?? [])
            ..add(payment);

      final updatedRecord = SalaryRecord(
        id: existingRecord?.id ?? 'sal_${emp.id}_$month',
        employeeId: emp.id,
        employeeName: emp.name,
        month: month,
        basicSalary: basic,
        additions: additions,
        deductions: deductions,
        advancesDeducted: finalAdvanceDeduct,
        paidAmount: alreadyPaid + amountToDisburse,
        payments: updatedPayments,
        paymentMethod: 'كاش',
        paymentDate: salaryDate,
        notes: 'صرف جماعي نقداً',
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
          if (_advances[i].employeeId == emp.id &&
              _advances[i].month == month &&
              _advances[i].remainingAmount > 0) {
            final adv = _advances[i];
            final canDeduct = adv.remainingAmount;
            if (remToDeduct <= canDeduct) {
              _advances[i] =
                  adv.copyWith(paidAmount: adv.paidAmount + remToDeduct);
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
        date: salaryDate,
        month: month,
        type: TransactionType.salary,
        amount: amountToDisburse,
        isCredit: false,
        title: 'مرتب: ${emp.name} (شهر $month)',
        notes: finalAdvanceDeduct > 0
            ? 'صرف كاش بعد خصم سلفة الشهر (${finalAdvanceDeduct.toStringAsFixed(0)} ج)'
            : 'صرف كاش بالكامل',
        referenceId: updatedRecord.id,
        createdAt: DateTime.now(),
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

  // -------------------------------------------------------------
  // EXCEPTIONAL CASES & AUDIT SUMMARY (Requirement #6)
  // -------------------------------------------------------------

  /// Summary of exceptional cases for a given month.
  Map<String, dynamic> getExceptionalCasesSummary(String month) {
    // 1. Unpaid or partially paid salaries
    final unpaidSalaries = <Map<String, dynamic>>[];
    for (final emp in _employees.where((e) => e.isActive)) {
      final rec = getEmployeeSalaryRecord(emp.id, month);
      if (rec == null) {
        unpaidSalaries.add({
          'employee': emp,
          'record': null,
          'status': 'غير مدفوع (لم يتم إنشاء سجل)',
          'unpaidAmount': emp.salary,
        });
      } else if (!rec.isFullyPaid) {
        unpaidSalaries.add({
          'employee': emp,
          'record': rec,
          'status': rec.statusLabel,
          'unpaidAmount': rec.remainingUnpaidSalary,
        });
      }
    }

    // 2. Outstanding or undeducted advances for this month
    final outstandingAdvances = _advances
        .where((a) =>
            a.month == month && (a.remainingAmount > 0 || a.isOutstanding))
        .toList();

    // 3. Audit entries in salary records for this month
    final auditLogs = <Map<String, dynamic>>[];
    for (final s in _salaries.where((s) => s.month == month)) {
      for (final a in s.auditLog) {
        auditLogs.add({
          'employeeName': s.employeeName,
          'timestamp': a.timestamp,
          'action': a.action,
          'details': a.details,
        });
      }
    }

    final totalUnpaidSalary = unpaidSalaries.fold<double>(
      0.0,
      (sum, item) => sum + (item['unpaidAmount'] as double),
    );

    final totalOutstandingAdv = outstandingAdvances.fold<double>(
      0.0,
      (sum, item) => sum + item.remainingAmount,
    );

    return {
      'month': month,
      'unpaidSalaries': unpaidSalaries,
      'totalUnpaidSalary': totalUnpaidSalary,
      'outstandingAdvances': outstandingAdvances,
      'totalOutstandingAdvances': totalOutstandingAdv,
      'auditLogs': auditLogs,
      'isPeriodClosed': getPeriodForMonth(month)?.isClosed ?? false,
    };
  }

  // -------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------

  static DateTime getDayOneOfMonth(String monthStr) {
    try {
      final parts = monthStr.split('-');
      if (parts.length >= 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateTime(year, month, 1, 10, 0);
      }
    } catch (_) {}
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1, 10, 0);
  }

  List<Expense> getEmployeeExpenses(String employeeId) {
    return _expenses
        .where((e) => e.employeeId == employeeId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getEmployeeTotalExpenses(String employeeId) {
    return _expenses
        .where((e) => e.employeeId == employeeId)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  }
}
