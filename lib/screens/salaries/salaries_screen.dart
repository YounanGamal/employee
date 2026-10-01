import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/salary_record.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/alert_banner.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import 'pay_salary_dialog.dart';

class SalariesScreen extends StatefulWidget {
  const SalariesScreen({super.key});

  @override
  State<SalariesScreen> createState() => _SalariesScreenState();
}

class _SalariesScreenState extends State<SalariesScreen> {
  String _filter = 'all';
  final currencyFormat = NumberFormat('#,##0', 'en_US');
  final dateFormat = DateFormat('yyyy/MM/dd');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selectedMonth = provider.selectedMonth;

    final activeEmployees = provider.employees.where((e) => e.isActive).toList();

    final List<Map<String, dynamic>> items = activeEmployees.map((emp) {
      final rec = provider.getEmployeeSalaryRecord(emp.id, selectedMonth);
      return {
        'employee': emp,
        'record': rec,
        'isPaid': rec?.isPaid ?? false,
      };
    }).toList();

    final filteredItems = items.where((item) {
      final isPaid = item['isPaid'] as bool;
      if (_filter == 'paid') return isPaid;
      if (_filter == 'unpaid') return !isPaid;
      return true;
    }).toList();

    final paidCount = items.where((i) => i['isPaid'] as bool).length;
    final unpaidCount = items.length - paidCount;
    final totalPaidAmount = provider.totalPaidSalariesForSelectedMonth;

    return Scaffold(
      appBar: AppBar(
        title: Text('صرف المرتبات ($selectedMonth)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'طباعة تقرير المرتبات (PDF)',
            onPressed: () async {
              final salaries = provider.salaries
                  .where((s) => s.month == selectedMonth)
                  .toList();
              await PdfExportService.printSalariesReport(
                salaries: salaries,
                month: selectedMonth,
                context: context,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.green),
            tooltip: 'تصدير المرتبات (Excel)',
            onPressed: () {
              final salaries = provider.salaries
                  .where((s) => s.month == selectedMonth)
                  .toList();
              ExcelExportService.exportSalariesCsv(salaries, selectedMonth);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تصدير تقرير المرتبات إلى ملف Excel بنجاح'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const PaySalaryDialog(),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('صرف مرتب جديد'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الشهر: $selectedMonth',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'إجمالي المدفوع: ${currencyFormat.format(totalPaidAmount)} ج',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.teal.shade800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildFilterTab('الكل (${items.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterTab('مدفوع ($paidCount)', 'paid', color: Colors.green),
                    const SizedBox(width: 8),
                    _buildFilterTab('متبقي ($unpaidCount)', 'unpaid',
                        color: AppTheme.warningOrange),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (unpaidCount > 0 && _filter != 'paid') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AlertBanner(
                title: '⚠️ مرتبات مستحقة',
                message: '$unpaidCount عمال لم يتم صرف مرتباتهم لشهر سبتمبر حتى الآن.',
                buttonText: 'صرف لأول عامل',
                onAction: () {
                  final firstUnpaid = items.firstWhere(
                    (i) => !(i['isPaid'] as bool),
                  )['employee'];
                  showDialog(
                    context: context,
                    builder: (_) => PaySalaryDialog(preselectedEmployee: firstUnpaid),
                  );
                },
              ),
            ),
          ],

          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد سجلات مرتبات مطابقة',
                      style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = filteredItems[i];
                      final emp = item['employee'];
                      final SalaryRecord? rec = item['record'];
                      final bool isPaid = item['isPaid'];

                      final displaySalary = rec != null ? rec.netSalary : emp.salary;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isPaid
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      isPaid
                                          ? Icons.check_circle_outline
                                          : Icons.pending_actions,
                                      color: isPaid
                                          ? Colors.green.shade700
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          emp.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        Text(
                                          'المرتب الأساسي: ${emp.salary.toStringAsFixed(0)} ج',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isPaid
                                            ? Colors.green.shade300
                                            : Colors.orange.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      isPaid ? 'مدفوع نقداً' : 'غير مدفوع',
                                      style: TextStyle(
                                        color: isPaid
                                            ? Colors.green.shade800
                                            : Colors.orange.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (rec != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'إضافي: +${rec.additions.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.green),
                                      ),
                                      Text(
                                        'خصومات: -${rec.deductions.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.red),
                                      ),
                                      Text(
                                        'سلف: -${rec.advancesDeducted.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.amber),
                                      ),
                                      Text(
                                        'الصافي: ${rec.netSalary.toStringAsFixed(0)} ج',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isPaid && rec?.paymentDate != null
                                        ? 'تاريخ الصرف: ${dateFormat.format(rec!.paymentDate!)}'
                                        : 'مستحق: ${displaySalary.toStringAsFixed(0)} ج',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (!isPaid)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => PaySalaryDialog(
                                            preselectedEmployee: emp,
                                            existingRecord: rec,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.attach_money, size: 16),
                                      label: const Text('صرف الآن'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                      ),
                                    )
                                  else
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => PaySalaryDialog(
                                            preselectedEmployee: emp,
                                            existingRecord: rec,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: const Text('تعديل الصرف'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String key, {Color? color}) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = key),
      selectedColor: (color ?? AppTheme.primary).withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? (color ?? AppTheme.primary) : Colors.grey.shade700,
      ),
    );
  }
}
