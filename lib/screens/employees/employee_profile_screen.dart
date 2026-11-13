import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/advance.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import 'employee_dialog.dart';
import '../salaries/pay_salary_screen.dart';
import '../advances/add_advance_dialog.dart';
import '../expenses/add_expense_screen.dart';

class EmployeeProfileScreen extends StatelessWidget {
  final String employeeId;

  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final employee = provider.getEmployeeById(employeeId);

    if (employee == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ملف العامل')),
        body: const Center(child: Text('لم يتم العثور على بيانات العامل')),
      );
    }

    final remainingAdvances = provider.getEmployeeRemainingAdvances(employee.id);
    final historicalAdvances = provider.getEmployeeOutstandingHistoricalAdvances(employee.id);
    final lastPaidSalary = provider.getEmployeeLastPaidSalary(employee.id);
    final totalPaid = provider.getEmployeeTotalPaid(employee.id);
    final salaries = provider.getEmployeeSalaries(employee.id);
    final advances = provider.getEmployeeAdvances(employee.id);
    final disbursements = provider.getEmployeeExpenses(employee.id);
    final totalDisbursed = provider.getEmployeeTotalExpenses(employee.id);

    final dateFormat = DateFormat('yyyy/MM/dd');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(employee.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'تعديل البيانات',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => EmployeeDialog(employee: employee),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'خيارات إضافية',
              onSelected: (value) async {
                if (value == 'pdf') {
                  await PdfExportService.printEmployeeStatement(
                    emp: employee,
                    salaries: salaries,
                    advances: advances,
                    disbursements: disbursements,
                    totalPaid: totalPaid,
                    remainingAdvances: remainingAdvances,
                    context: context,
                  );
                } else if (value == 'excel') {
                  ExcelExportService.exportEmployeeStatementCsv(
                    employee,
                    salaries,
                    advances,
                    disbursements,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تصدير كشف الحساب بتنسيق Excel بنجاح'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                } else if (value == 'toggle') {
                  provider.toggleEmployeeStatus(employee.id);
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تأكيد الحذف'),
                      content: Text('هل أنت متأكد من حذف العامل "${employee.name}"؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('حذف'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await provider.deleteEmployee(employee.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حذف العامل بنجاح')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('طباعة كشف حساب (PDF)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_view, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('تصدير كشف حساب (Excel)'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        employee.isActive ? Icons.block : Icons.check_circle_outline,
                        color: employee.isActive ? Colors.orange : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(employee.isActive ? 'تعطيل العامل' : 'تنشيط العامل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('حذف العامل نهائياً'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          employee.name.isNotEmpty
                              ? employee.name.trim().split(' ').first[0]
                              : '؟',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  employee.phone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (employee.nationalId.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.badge_outlined, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    'الرقم القومي: ${employee.nationalId}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: employee.isActive ? Colors.green.shade400 : Colors.red.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          employee.isActive ? 'نشط' : 'غير نشط',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (employee.notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ملاحظات: ${employee.notes}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'المرتب الأساسي',
                    value: '${employee.salary.toStringAsFixed(0)} ج',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'آخر مرتب',
                    value: lastPaidSalary != null
                        ? '${lastPaidSalary.netSalary.toStringAsFixed(0)} ج'
                        : 'لم يصرف بعد',
                    subtitle: lastPaidSalary?.paymentDate != null
                        ? dateFormat.format(lastPaidSalary!.paymentDate!)
                        : null,
                    icon: Icons.history_rounded,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'سلف شهر ${provider.selectedMonth}',
                    value: '${remainingAdvances.toStringAsFixed(0)} ج',
                    subtitle: remainingAdvances > 0
                        ? 'مستحق السداد'
                        : (historicalAdvances > 0
                            ? 'سلف سابقة: ${historicalAdvances.toStringAsFixed(0)} ج'
                            : 'لا توجد سلف'),
                    icon: Icons.request_quote_outlined,
                    color: remainingAdvances > 0
                        ? Colors.amber.shade800
                        : Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'إجمالي المدفوع له',
                    value: '${totalPaid.toStringAsFixed(0)} ج',
                    subtitle: 'مرتبات وسلف سابقة',
                    icon: Icons.payments_outlined,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              title: 'إجمالي المنصرف له (علاج / مكافآت)',
              value: '${totalDisbursed.toStringAsFixed(0)} ج',
              subtitle: 'مبالغ غير مخصومة من المرتب ولا تُسترد',
              icon: Icons.medical_services_outlined,
              color: Colors.teal.shade700,
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => PaySalaryScreen(
                            preselectedEmployee: employee,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('صرف مرتب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AddAdvanceDialog(
                          preselectedEmployee: employee,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('إعطاء سلفة'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AddExpenseScreen(
                        preselectedEmployee: employee,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.medical_services_outlined, size: 18),
                label: const Text(
                  'صرف للعامل (علاج / مكافأة / مساعدة) 💊',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade700,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: [
                  Tab(text: 'المرتبات (${salaries.length})'),
                  Tab(text: 'السلف (${advances.length})'),
                  Tab(text: 'الصرف والبدلات (${disbursements.length})'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 380,
              child: TabBarView(
                children: [
                  salaries.isEmpty
                      ? const Center(
                          child: Text(
                            'لا يوجد سجل مرتبات مسجل لهذا العامل',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        )
                      : ListView.separated(
                          itemCount: salaries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final sal = salaries[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: sal.isPaid
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                child: Icon(
                                  sal.isPaid
                                      ? Icons.check_circle_outline
                                      : Icons.pending_outlined,
                                  color: sal.isPaid
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                              title: Text(
                                'شهر: ${sal.month}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              subtitle: Text(
                                'أساسي: ${sal.basicSalary.toStringAsFixed(0)} ج | إضافي: +${sal.additions.toStringAsFixed(0)} | خصم: -${(sal.deductions + sal.advancesDeducted).toStringAsFixed(0)} ج',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${sal.netSalary.toStringAsFixed(0)} ج',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: sal.isPaid
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                  Text(
                                    sal.isPaid ? 'مدفوع' : 'مستحق',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sal.isPaid
                                          ? Colors.green.shade600
                                          : Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  advances.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد سلف مسجلة لهذا العامل',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        )
                      : ListView.separated(
                          itemCount: advances.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final adv = advances[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: adv.isFullyPaid
                                    ? Colors.green.shade50
                                    : Colors.amber.shade50,
                                child: Icon(
                                  adv.isFullyPaid
                                      ? Icons.check
                                      : Icons.hourglass_bottom,
                                  color: adv.isFullyPaid
                                      ? Colors.green.shade700
                                      : Colors.amber.shade800,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${adv.amount.toStringAsFixed(0)} ج',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(adv.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    'مسدد: ${adv.paidAmount.toStringAsFixed(0)} ج | متبقي: ${adv.remainingAmount.toStringAsFixed(0)} ج',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (adv.notes.isNotEmpty)
                                    Text(
                                      adv.notes,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: !adv.isFullyPaid
                                  ? TextButton(
                                      onPressed: () {
                                        _showPayAdvanceDialog(
                                          context,
                                          provider,
                                          adv,
                                        );
                                      },
                                      child: const Text('سداد يدوي'),
                                    )
                                  : const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                            );
                          },
                        ),

                  disbursements.isEmpty
                      ? const Center(
                          child: Text(
                            'لا يوجد سجل منصرفات أو مكافآت مسجلة لهذا العامل',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        )
                      : ListView.separated(
                          itemCount: disbursements.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final exp = disbursements[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.shade50,
                                child: Icon(
                                  Icons.medical_services_outlined,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    exp.category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '- ${exp.amount.toStringAsFixed(0)} ج',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exp.description,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'التاريخ: ${dateFormat.format(exp.date)}${exp.notes.isNotEmpty ? " • ${exp.notes}" : ""}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('تأكيد الحذف'),
                                      content: const Text('هل تريد حذف هذا المنصرف وإرجاع المبلغ إلى الخزنة؟'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, false),
                                          child: const Text('إلغاء'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('حذف'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    provider.deleteExpense(exp.id);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayAdvanceDialog(
    BuildContext context,
    AppProvider provider,
    Advance advance,
  ) {
    final controller = TextEditingController(
      text: advance.remainingAmount.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سداد سلفة يدوي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العامل: ${advance.employeeName}'),
            const SizedBox(height: 6),
            Text('المتبقي: ${advance.remainingAmount.toStringAsFixed(0)} ج'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ السداد (ج.م)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0.0;
              if (val <= 0) return;
              provider.repayAdvanceDirectly(advance.id, val);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تسجيل سداد السلفة بنجاح')),
              );
            },
            child: const Text('تأكيد السداد'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  fontFamily: 'Cairo',
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              fontFamily: 'Cairo',
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
