import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/advance.dart';
import '../models/salary_record.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/treasury_transaction.dart';

class ExcelExportService {
  static const String _bom = '\uFEFF';

  static String _num(double val) => val.toStringAsFixed(2);
  static String _date(DateTime d) => DateFormat('yyyy/MM/dd').format(d);

  static String exportSalariesCsv(List<SalaryRecord> salaries, String month) {
    final sb = StringBuffer();
    sb.write(_bom);
    sb.writeln('تقرير مرتبات شهر,$month');
    sb.writeln('م,اسم العامل,المرتب الأساسي,الإضافات,الخصومات,سلف مخصومة,صافي المرتب,طريقة الدفع,حالة الدفع,تاريخ الصرف,ملاحظات');

    int index = 1;
    for (final s in salaries) {
      final statusStr = s.isPaid ? 'مدفوع' : 'غير مدفوع';
      final pDate = s.paymentDate != null ? _date(s.paymentDate!) : '-';
      sb.writeln('$index,"${s.employeeName}",${_num(s.basicSalary)},${_num(s.additions)},${_num(s.deductions)},${_num(s.advancesDeducted)},${_num(s.netSalary)},"${s.paymentMethod}","$statusStr","$pDate","${s.notes}"');
      index++;
    }

    final totalBasic = salaries.fold<double>(0, (sum, s) => sum + s.basicSalary);
    final totalAdd = salaries.fold<double>(0, (sum, s) => sum + s.additions);
    final totalDed = salaries.fold<double>(0, (sum, s) => sum + s.deductions);
    final totalAdv = salaries.fold<double>(0, (sum, s) => sum + s.advancesDeducted);
    final totalNet = salaries.fold<double>(0, (sum, s) => sum + s.netSalary);

    sb.writeln('');
    sb.writeln('الإجمالي,-,${_num(totalBasic)},${_num(totalAdd)},${_num(totalDed)},${_num(totalAdv)},${_num(totalNet)},-,-,-,-');
    return sb.toString();
  }

  static String exportAdvancesCsv(List<Advance> advances) {
    final sb = StringBuffer();
    sb.write(_bom);
    sb.writeln('تقرير السلف وحالتها');
    sb.writeln('م,اسم العامل,قيمة السلفة,تاريخ السلفة,المبلغ المسدد,المتبقي,خصم تلقائي من المرتب,الحالة,ملاحظات');

    int index = 1;
    for (final a in advances) {
      final autoStr = a.autoDeductFromSalary ? 'نعم' : 'لا';
      final statusStr = a.isFullyPaid ? 'مسددة بالكامل' : (a.paidAmount > 0 ? 'مسددة جزئياً' : 'مستحقة');
      sb.writeln('$index,"${a.employeeName}",${_num(a.amount)},"${_date(a.date)}",${_num(a.paidAmount)},${_num(a.remainingAmount)},"$autoStr","$statusStr","${a.notes}"');
      index++;
    }

    final totalAmount = advances.fold<double>(0, (sum, a) => sum + a.amount);
    final totalPaid = advances.fold<double>(0, (sum, a) => sum + a.paidAmount);
    final totalRem = advances.fold<double>(0, (sum, a) => sum + a.remainingAmount);

    sb.writeln('');
    sb.writeln('الإجمالي,-,${_num(totalAmount)},-,${_num(totalPaid)},${_num(totalRem)},-,-,-');
    return sb.toString();
  }

  static String exportIncomeCsv(List<Income> incomes) {
    final sb = StringBuffer();
    sb.write(_bom);
    sb.writeln('تقرير الإيرادات والواردات');
    sb.writeln('م,المبلغ,السبب / المصدر,التاريخ,ملاحظات');

    int index = 1;
    for (final inc in incomes) {
      sb.writeln('$index,${_num(inc.amount)},"${inc.reason}","${_date(inc.date)}","${inc.notes}"');
      index++;
    }

    final total = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    sb.writeln('');
    sb.writeln('الإجمالي,${_num(total)},-,-,-');
    return sb.toString();
  }

  static String exportExpensesCsv(List<Expense> expenses) {
    final sb = StringBuffer();
    sb.write(_bom);
    sb.writeln('تقرير المصروفات والمنصرف');
    sb.writeln('م,المبلغ,نوع المصروف,البيان,التاريخ,ملاحظات');

    int index = 1;
    for (final exp in expenses) {
      sb.writeln('$index,${_num(exp.amount)},"${exp.category}","${exp.description}","${_date(exp.date)}","${exp.notes}"');
      index++;
    }

    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    sb.writeln('');
    sb.writeln('الإجمالي,${_num(total)},-,-,-,-');
    return sb.toString();
  }

  static String exportTreasuryCsv(List<TreasuryTransaction> txs, double currentBalance) {
    final sb = StringBuffer();
    sb.write(_bom);
    sb.writeln('تقرير حركة الخزنة');
    sb.writeln('رصيد الخزنة الحالي,${_num(currentBalance)} ج.م');
    sb.writeln('م,التاريخ,نوع العملية,المبلغ,الاتجاه,البيان,ملاحظات');

    int index = 1;
    for (final t in txs) {
      final direction = t.isCredit ? 'وارد (+)' : 'منصرف (-)';
      final signAmount = t.isCredit ? '+${_num(t.amount)}' : '-${_num(t.amount)}';
      sb.writeln('$index,"${_date(t.date)}","${t.typeLabel}",$signAmount,"$direction","${t.title}","${t.notes}"');
      index++;
    }
    return sb.toString();
  }

  static String exportEmployeeStatementCsv(
    Employee emp,
    List<SalaryRecord> salaries,
    List<Advance> advances,
  ) {
    final sb = StringBuffer();
    sb.write(_bom);
    sb.writeln('كشف حساب الموظف,"${emp.name}"');
    sb.writeln('رقم الموبايل,"${emp.phone}"');
    sb.writeln('المرتب الأساسي,${_num(emp.salary)}');
    sb.writeln('حالة الموظف,${emp.isActive ? "نشط" : "غير نشط"}');
    sb.writeln('');

    sb.writeln('--- سجل المرتبات ---');
    sb.writeln('الشهر,الأساسي,إضافات,خصومات,سلف,الصافي,الحالة,تاريخ الصرف');
    for (final s in salaries) {
      sb.writeln('"${s.month}",${_num(s.basicSalary)},${_num(s.additions)},${_num(s.deductions)},${_num(s.advancesDeducted)},${_num(s.netSalary)},"${s.isPaid ? "مدفوع" : "غير مدفوع"}","${s.paymentDate != null ? _date(s.paymentDate!) : "-"}"');
    }
    sb.writeln('');

    sb.writeln('--- سجل السلف ---');
    sb.writeln('التاريخ,قيمة السلفة,المسدد,المتبقي,الحالة');
    for (final a in advances) {
      sb.writeln('"${_date(a.date)}",${_num(a.amount)},${_num(a.paidAmount)},${_num(a.remainingAmount)},"${a.isFullyPaid ? "مسددة" : "متبقية"}"');
    }

    return sb.toString();
  }
}
