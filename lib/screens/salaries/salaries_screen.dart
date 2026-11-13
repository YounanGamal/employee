import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/salary_record.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/month_picker_dialog.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import 'pay_salary_screen.dart';
import 'exceptional_cases_dialog.dart';

class SalariesScreen extends StatefulWidget {
  const SalariesScreen({super.key});

  @override
  State<SalariesScreen> createState() => _SalariesScreenState();
}

class _SalariesScreenState extends State<SalariesScreen> {
  String _filter = 'all'; // all, full, partial, unpaid
  final currencyFormat = NumberFormat('#,##0', 'en_US');
  final dateFormat = DateFormat('yyyy/MM/dd');

  void _pickMonth(BuildContext context, AppProvider provider) async {
    final selected = await MonthPickerDialog.show(
      context,
      initialMonth: provider.selectedMonth,
      allowAllMonths: false,
    );
    if (selected != null && selected.isNotEmpty) {
      await provider.setSelectedMonth(selected);
    }
  }

  void _showCorrectionDialog(BuildContext context, SalaryRecord rec) {
    final basicCtrl =
        TextEditingController(text: rec.basicSalary.toStringAsFixed(0));
    final addCtrl =
        TextEditingController(text: rec.additions.toStringAsFixed(0));
    final dedCtrl =
        TextEditingController(text: rec.deductions.toStringAsFixed(0));
    final advCtrl =
        TextEditingController(text: rec.advancesDeducted.toStringAsFixed(0));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تصحيح سجل مرتب: ${rec.employeeName}',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'يمكنك تصحيح القيم المسجلة خطأً مع حفظ سبب التعديل في سجل التدقيق المالي.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: basicCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المرتب الأساسي (ج.م)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'إضافي ومكافآت (ج.م)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'خصومات وجزاءات (ج.م)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: advCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سلف مستقطعة (ج.م)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'سبب التصحيح / ملاحظة التدقيق *',
                  hintText: 'مثلاً: خطأ في إدخال الخصم، مراجعة الإضافي...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBasic = double.tryParse(basicCtrl.text.trim()) ?? rec.basicSalary;
              final newAdd = double.tryParse(addCtrl.text.trim()) ?? 0.0;
              final newDed = double.tryParse(dedCtrl.text.trim()) ?? 0.0;
              final newAdv = double.tryParse(advCtrl.text.trim()) ?? 0.0;
              final reason = reasonCtrl.text.trim();

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى كتابة سبب التصحيح للتدقيق')),
                );
                return;
              }

              final provider = context.read<AppProvider>();
              await provider.recordSalaryCorrection(
                recordId: rec.id,
                newBasicSalary: newBasic,
                newAdditions: newAdd,
                newDeductions: newDed,
                newAdvancesDeducted: newAdv,
                auditReason: reason,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تصحيح السجل وتسجيل العملية في سجل التدقيق بنجاح'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              }
            },
            child: const Text('حفظ التصحيح والتدقيق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selectedMonth = provider.selectedMonth;

    final activeEmployees =
        provider.employees.where((e) => e.isActive).toList();

    final List<Map<String, dynamic>> items = activeEmployees.map((emp) {
      final rec = provider.getEmployeeSalaryRecord(emp.id, selectedMonth);
      final isFull = rec != null && rec.isFullyPaid;
      final isPart = rec != null && rec.isPartiallyPaid;
      final isUnpaid = rec == null || rec.isUnpaid;

      return {
        'employee': emp,
        'record': rec,
        'isFull': isFull,
        'isPart': isPart,
        'isUnpaid': isUnpaid,
      };
    }).toList();

    final filteredItems = items.where((item) {
      if (_filter == 'full') return item['isFull'] as bool;
      if (_filter == 'partial') return item['isPart'] as bool;
      if (_filter == 'unpaid') return item['isUnpaid'] as bool;
      return true;
    }).toList();

    final fullPaidCount = items.where((i) => i['isFull'] as bool).length;
    final partialPaidCount = items.where((i) => i['isPart'] as bool).length;
    final unpaidCount = items.where((i) => i['isUnpaid'] as bool).length;
    final totalPaidAmount = provider.totalPaidSalariesForSelectedMonth;
    final totalUnpaidAmount = provider.totalUnpaidSalariesForSelectedMonth;

    return Scaffold(
      appBar: AppBar(
        title: Text('مرتبات شهر $selectedMonth 💵'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppTheme.primary),
            tooltip: 'تغيير الشهر المالي',
            onPressed: () => _pickMonth(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.fact_check, color: Colors.orange),
            tooltip: 'تقرير الحالات الاستثنائية وإغلاق الشهر',
            onPressed: () => ExceptionalCasesDialog.show(context, selectedMonth),
          ),
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
                  content: Text('تم تصدير تقرير المرتبات بنجاح بصيغة Excel'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PaySalaryScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('تسجيل / صرف مرتب'),
      ),
      body: Column(
        children: [
          // Month Selector Bar & Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _pickMonth(context, provider),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available,
                              size: 18, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'الشهر المالي: $selectedMonth',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: 'Cairo',
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'مدفوع: ${currencyFormat.format(totalPaidAmount)} ج',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'مستحق: ${currencyFormat.format(totalUnpaidAmount)} ج',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.expenseRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterTab('الكل (${items.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        'مدفوع بالكامل ($fullPaidCount)',
                        'full',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        'مدفوع جزئياً ($partialPaidCount)',
                        'partial',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        'غير مدفوع ($unpaidCount)',
                        'unpaid',
                        color: AppTheme.warningOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Alert banner if there are unpaid salaries
          if ((unpaidCount > 0 || partialPaidCount > 0) && _filter != 'full') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AlertBanner(
                title: '⚠️ مرتبات مستحقة لشهر $selectedMonth',
                message:
                    'يوجد $unpaidCount عمال غير مدفوع لهم و $partialPaidCount مدفوع جزئياً بإجمالي مستحق ${currencyFormat.format(totalUnpaidAmount)} ج.',
                buttonText: 'كشف الحالات الاستثنائية',
                onAction: () =>
                    ExceptionalCasesDialog.show(context, selectedMonth),
              ),
            ),
          ],

          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد سجلات مرتبات مطابقة للتصفية',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontFamily: 'Cairo',
                      ),
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
                      final bool isFull = item['isFull'];
                      final bool isPart = item['isPart'];

                      final displayBasic = rec?.basicSalary ?? emp.salary;
                      final netSalary = rec?.netSalary ?? emp.salary;
                      final paidAmount = rec?.paidAmount ?? 0.0;
                      final remaining = rec?.remainingUnpaidSalary ?? emp.salary;

                      Color statusColor = Colors.orange.shade800;
                      String statusText = 'غير مدفوع';
                      IconData statusIcon = Icons.pending_actions;
                      if (isFull) {
                        statusColor = Colors.green.shade700;
                        statusText = 'مدفوع بالكامل';
                        statusIcon = Icons.check_circle_outline;
                      } else if (isPart) {
                        statusColor = Colors.blue.shade700;
                        statusText = 'مدفوع جزئياً';
                        statusIcon = Icons.timelapse;
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        statusColor.withValues(alpha: 0.1),
                                    child: Icon(statusIcon,
                                        color: statusColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          'المرتب الأساسي للشهر: ${displayBasic.toStringAsFixed(0)} ج  (الملف: ${emp.salary.toStringAsFixed(0)} ج)',
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
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: statusColor
                                              .withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Calculation Details Row
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
                                      'إضافي: +${(rec?.additions ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.green),
                                    ),
                                    Text(
                                      'خصم: -${(rec?.deductions ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.red),
                                    ),
                                    Text(
                                      'سلف الشهر: -${(rec?.advancesDeducted ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.amber),
                                    ),
                                    Text(
                                      'الصافي: ${netSalary.toStringAsFixed(0)} ج',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Paid & Remaining Stats
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تم الصرف: ${currencyFormat.format(paidAmount)} ج  |  المتبقي: ${currencyFormat.format(remaining)} ج',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: remaining > 0
                                              ? AppTheme.expenseRed
                                              : Colors.green.shade800,
                                        ),
                                      ),
                                      if (rec?.paymentDate != null)
                                        Text(
                                          'آخر صرف: ${dateFormat.format(rec!.paymentDate!)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      if (rec != null && rec.auditLog.isNotEmpty)
                                        Text(
                                          '📋 توجد ${rec.auditLog.length} تعديلات مسجلة في سجل التدقيق',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (rec != null)
                                        IconButton(
                                          icon: const Icon(Icons.edit_note,
                                              color: Colors.blue),
                                          tooltip: 'تصحيح وتدقيق السجل',
                                          onPressed: () =>
                                              _showCorrectionDialog(context, rec),
                                        ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PaySalaryScreen(
                                                preselectedEmployee: emp,
                                                existingRecord: rec,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          isFull
                                              ? Icons.edit
                                              : Icons.attach_money,
                                          size: 15,
                                        ),
                                        label: Text(
                                          isFull
                                              ? 'تعديل الصرف'
                                              : (isPart
                                                  ? 'صرف المتبقي'
                                                  : 'صرف الآن'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFull
                                              ? Colors.grey.shade800
                                              : AppTheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                        ),
                                      ),
                                    ],
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
