import '../models/employee.dart';
import '../models/advance.dart';
import '../models/salary_record.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/treasury_transaction.dart';

class SeedData {
  static List<Employee> getEmployees() {
    final names = [
      'أحمد محمد',
      'محمد علي',
      'محمود حسن',
      'سارة خالد',
      'خالد مصطفى',
      'كريم سامي',
      'فاطمة إبراهيم',
      'عمر يوسف',
      'منى عبد الله',
      'طارق زين',
      'ياسر محمود',
      'هدى فؤاد',
      'أشرف نبيل',
      'إيمان صابر',
      'وليد عادل',
      'مريم عبد الرحمن',
      'حسام الشريف',
      'رنا كمال',
      'مصطفى جمال',
      'أميرة سعيد',
      'إسلام عزت',
      'نوران حسني',
      'باسم فكري',
      'زينب حامد',
      'سامح توفيق',
    ];

    final phones = [
      '01012345671',
      '01012345672',
      '01123456783',
      '01234567894',
      '01056789015',
      '01187654326',
      '01278901237',
      '01099887768',
      '01555443329',
      '01033221100',
      '01144556677',
      '01266778899',
      '01088990011',
      '01511223344',
      '01177889922',
      '01022334455',
      '01233445566',
      '01544556677',
      '01155667788',
      '01066778899',
      '01277889900',
      '01588990011',
      '01199001122',
      '01000112233',
      '01211223344',
    ];

    final salaries = [
      8000.0,
      6000.0,
      5500.0,
      5000.0,
      4800.0,
      5200.0,
      4500.0,
      6500.0,
      4000.0,
      5000.0,
      4200.0,
      4500.0,
      5000.0,
      4000.0,
      4800.0,
      5000.0,
      4500.0,
      4200.0,
      6000.0,
      4500.0,
      5000.0,
      4000.0,
      4500.0,
      4200.0,
      4800.0,
    ];

    return List.generate(25, (index) {
      return Employee(
        id: 'emp_${index + 1}',
        name: names[index],
        phone: phones[index],
        nationalId: '29${(85 + index).toString().padLeft(2, "0")}01011234${(10 + index).toString().padLeft(2, "0")}',
        salary: salaries[index],
        notes: index == 0
            ? 'مدير قسم المبيعات'
            : index == 1
                ? 'مشرف التشغيل'
                : 'موظف منتظم',
        isActive: true,
        joinedDate: DateTime(2025, 1, 1).add(Duration(days: index * 18)),
      );
    });
  }

  static List<Advance> getAdvances() {
    return [
      Advance(
        id: 'adv_ahmed',
        employeeId: 'emp_1',
        employeeName: 'أحمد محمد',
        amount: 2000.0,
        date: DateTime(2026, 9, 12),
        paidAmount: 0.0,
        autoDeductFromSalary: false,
        notes: 'سلفة شخصية',
      ),
      Advance(
        id: 'adv_1',
        employeeId: 'emp_2',
        employeeName: 'محمد علي',
        amount: 2000.0,
        date: DateTime(2026, 9, 30),
        paidAmount: 0.0,
        autoDeductFromSalary: true,
        notes: 'سلفة طارئة لشراء مستلزمات',
      ),
      Advance(
        id: 'adv_2',
        employeeId: 'emp_5',
        employeeName: 'خالد مصطفى',
        amount: 1500.0,
        date: DateTime(2026, 9, 15),
        paidAmount: 500.0,
        autoDeductFromSalary: true,
        notes: 'سلفة خاصة',
      ),
    ];
  }

  static List<SalaryRecord> getSalaries(List<Employee> employees) {
    const currentMonth = '2026-09';
    final records = <SalaryRecord>[];

    final paidAmounts = [
      8000.0,
      1800.0,
      1600.0,
      1500.0,
      1400.0,
      1500.0,
      1300.0,
      1700.0,
      1200.0,
      1500.0,
      1200.0,
      1300.0,
      1500.0,
      1200.0,
      1400.0,
      1500.0,
      1200.0,
      1200.0,
    ];

    for (int i = 0; i < 18; i++) {
      final emp = employees[i];
      final net = paidAmounts[i];
      records.add(SalaryRecord(
        id: 'sal_2026_09_${i + 1}',
        employeeId: emp.id,
        employeeName: emp.name,
        month: currentMonth,
        basicSalary: net,
        additions: 0.0,
        deductions: 0.0,
        advancesDeducted: 0.0,
        isPaid: true,
        paymentMethod: 'كاش',
        paymentDate: i == 0 ? DateTime(2026, 9, 30) : DateTime(2026, 9, 30 - (i % 5)),
        notes: 'تم صرف المرتب نقداً بالكامل',
      ));
    }

    // Historical records for Ahmed Mohamed to total 24,000 (8k July + 8k August + 8k September)
    records.add(SalaryRecord(
      id: 'sal_2026_07_1',
      employeeId: employees[0].id,
      employeeName: employees[0].name,
      month: '2026-07',
      basicSalary: 8000.0,
      isPaid: true,
      paymentMethod: 'كاش',
      paymentDate: DateTime(2026, 7, 30),
      notes: 'مرتب شهر يوليو',
    ));
    records.add(SalaryRecord(
      id: 'sal_2026_08_1',
      employeeId: employees[0].id,
      employeeName: employees[0].name,
      month: '2026-08',
      basicSalary: 8000.0,
      isPaid: true,
      paymentMethod: 'كاش',
      paymentDate: DateTime(2026, 8, 30),
      notes: 'مرتب شهر أغسطس',
    ));

    for (int i = 18; i < 25; i++) {
      final emp = employees[i];
      records.add(SalaryRecord(
        id: 'sal_2026_09_${i + 1}',
        employeeId: emp.id,
        employeeName: emp.name,
        month: currentMonth,
        basicSalary: emp.salary,
        additions: 0.0,
        deductions: 0.0,
        advancesDeducted: 0.0,
        isPaid: false,
        paymentMethod: 'كاش',
        paymentDate: null,
        notes: 'مستحق للصرف',
      ));
    }

    return records;
  }

  static List<Income> getIncomes() {
    return [
      Income(
        id: 'inc_1',
        amount: 35000.0,
        reason: 'إيراد عقود صيانة شهرية',
        date: DateTime(2026, 9, 5),
        notes: 'تحصيل كاش من العملاء',
      ),
      Income(
        id: 'inc_2',
        amount: 35000.0,
        reason: 'مبيعات نقدية للفرع الرئيسي',
        date: DateTime(2026, 9, 20),
        notes: 'دفعة نقدية بالخزينة',
      ),
      Income(
        id: 'inc_3',
        amount: 10000.0,
        reason: 'وارد مبيعات إضافية وخدمات',
        date: DateTime(2026, 9, 30),
        notes: 'توريد كاش خزينة',
      ),
    ];
  }

  static List<Expense> getExpenses() {
    return [
      Expense(
        id: 'exp_1',
        amount: 20000.0,
        category: 'إيجار',
        description: 'إيجار المقر الرئيسي لشهر سبتمبر',
        date: DateTime(2026, 9, 1),
        notes: 'سداد نقدي لمالك العقار',
      ),
      Expense(
        id: 'exp_2',
        amount: 8000.0,
        category: 'كهرباء ومرافق',
        description: 'سداد فواتير الكهرباء والمياه والإنترنت',
        date: DateTime(2026, 9, 10),
        notes: 'فواتير رسمية',
      ),
      Expense(
        id: 'exp_3',
        amount: 12000.0,
        category: 'صيانة',
        description: 'صيانة أجهزة التكييف والمعدات التشغيلية',
        date: DateTime(2026, 9, 18),
        notes: 'قطع غيار وفنيين',
      ),
      Expense(
        id: 'exp_4',
        amount: 5000.0,
        category: 'بوفيه وضيافة',
        description: 'مستلزمات بوفيه وضيافة ونثريات إدارية',
        date: DateTime(2026, 9, 30),
        notes: 'شراء نقدي',
      ),
    ];
  }

  static const double initialTreasuryBalance = 126000.0;

  static List<TreasuryTransaction> getTransactions() {
    return [
      TreasuryTransaction(
        id: 'trx_adv_ahmed',
        date: DateTime(2026, 9, 12),
        type: TransactionType.advancePayout,
        amount: 2000.0,
        isCredit: false,
        title: 'سلفة أحمد: أحمد محمد',
        notes: 'سلفة شخصية',
        referenceId: 'adv_ahmed',
      ),
      TreasuryTransaction(
        id: 'trx_1',
        date: DateTime(2026, 9, 1),
        type: TransactionType.expense,
        amount: 20000.0,
        isCredit: false,
        title: 'مصروف: إيجار المقر لشهر سبتمبر',
        notes: 'سداد نقدي',
        referenceId: 'exp_1',
      ),
      TreasuryTransaction(
        id: 'trx_2',
        date: DateTime(2026, 9, 5),
        type: TransactionType.income,
        amount: 35000.0,
        isCredit: true,
        title: 'وارد: إيراد عقود صيانة شهرية',
        notes: 'تحصيل كاش',
        referenceId: 'inc_1',
      ),
      TreasuryTransaction(
        id: 'trx_3',
        date: DateTime(2026, 9, 10),
        type: TransactionType.expense,
        amount: 8000.0,
        isCredit: false,
        title: 'مصروف: فواتير الكهرباء والمرافق',
        notes: 'فواتير رسمية',
        referenceId: 'exp_2',
      ),
      TreasuryTransaction(
        id: 'trx_4',
        date: DateTime(2026, 9, 18),
        type: TransactionType.expense,
        amount: 12000.0,
        isCredit: false,
        title: 'مصروف: صيانة معدات وتكييف',
        notes: 'قطع غيار',
        referenceId: 'exp_3',
      ),
      TreasuryTransaction(
        id: 'trx_5',
        date: DateTime(2026, 9, 20),
        type: TransactionType.income,
        amount: 35000.0,
        isCredit: true,
        title: 'وارد: مبيعات نقدية للفرع الرئيسي',
        notes: 'توريد كاش',
        referenceId: 'inc_2',
      ),
      TreasuryTransaction(
        id: 'trx_sal_batch',
        date: DateTime(2026, 9, 28),
        type: TransactionType.salary,
        amount: 24000.0,
        isCredit: false,
        title: 'مرتبات: صرف دفعة مرتبات العاملين (17 عامل)',
        notes: 'صرف نقدي كاش',
      ),
      TreasuryTransaction(
        id: 'trx_6',
        date: DateTime(2026, 9, 30, 9, 30),
        type: TransactionType.income,
        amount: 10000.0,
        isCredit: true,
        title: 'وارد: مبيعات إضافية وخدمات',
        notes: 'توريد كاش خزينة',
        referenceId: 'inc_3',
      ),
      TreasuryTransaction(
        id: 'trx_7',
        date: DateTime(2026, 9, 30, 11, 15),
        type: TransactionType.expense,
        amount: 5000.0,
        isCredit: false,
        title: 'مصروف: مستلزمات بوفيه وضيافة ونثريات',
        notes: 'شراء نقدي',
        referenceId: 'exp_4',
      ),
      TreasuryTransaction(
        id: 'trx_8',
        date: DateTime(2026, 9, 30, 13, 0),
        type: TransactionType.salary,
        amount: 8000.0,
        isCredit: false,
        title: 'مرتب أحمد: أحمد محمد (شهر 2026-09)',
        notes: 'صرف كاش',
        referenceId: 'sal_2026_09_1',
      ),
      TreasuryTransaction(
        id: 'trx_9',
        date: DateTime(2026, 9, 30, 14, 45),
        type: TransactionType.advancePayout,
        amount: 2000.0,
        isCredit: false,
        title: 'سلفة محمد: محمد علي',
        notes: 'سلفة نقدية طارئة',
        referenceId: 'adv_1',
      ),
    ];
  }
}
