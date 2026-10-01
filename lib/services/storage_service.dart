import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';
import '../models/advance.dart';
import '../models/salary_record.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/treasury_transaction.dart';

class StorageService {
  static const String _keyEmployees = 'app_employees';
  static const String _keyAdvances = 'app_advances';
  static const String _keySalaries = 'app_salaries';
  static const String _keyIncomes = 'app_incomes';
  static const String _keyExpenses = 'app_expenses';
  static const String _keyTransactions = 'app_transactions';
  static const String _keyInitialBalance = 'app_initial_balance';
  static const String _keyIsInitialized = 'app_is_initialized';

  Future<bool> isInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsInitialized) ?? false;
  }

  Future<void> setInitialized(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsInitialized, value);
  }

  Future<double> getInitialBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyInitialBalance) ?? 0.0;
  }

  Future<void> saveInitialBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyInitialBalance, balance);
  }

  Future<List<Employee>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyEmployees);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => Employee.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEmployees(List<Employee> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(employees.map((e) => e.toMap()).toList());
    await prefs.setString(_keyEmployees, jsonStr);
  }

  Future<List<Advance>> getAdvances() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAdvances);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => Advance.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAdvances(List<Advance> advances) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(advances.map((e) => e.toMap()).toList());
    await prefs.setString(_keyAdvances, jsonStr);
  }

  Future<List<SalaryRecord>> getSalaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySalaries);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => SalaryRecord.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSalaries(List<SalaryRecord> salaries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(salaries.map((e) => e.toMap()).toList());
    await prefs.setString(_keySalaries, jsonStr);
  }

  Future<List<Income>> getIncomes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyIncomes);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => Income.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveIncomes(List<Income> incomes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(incomes.map((e) => e.toMap()).toList());
    await prefs.setString(_keyIncomes, jsonStr);
  }

  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyExpenses);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => Expense.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(expenses.map((e) => e.toMap()).toList());
    await prefs.setString(_keyExpenses, jsonStr);
  }

  Future<List<TreasuryTransaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyTransactions);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => TreasuryTransaction.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TreasuryTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(transactions.map((e) => e.toMap()).toList());
    await prefs.setString(_keyTransactions, jsonStr);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
