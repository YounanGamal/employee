import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/treasury_transaction.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import '../../widgets/month_picker_dialog.dart';
import '../salaries/exceptional_cases_dialog.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final month = provider.selectedMonth;

    final incomeMonth = provider.totalIncomeForSelectedMonth;
    final expenseMonth = provider.totalExpenseForSelectedMonth;
    final salariesMonth = provider.totalPaidSalariesForSelectedMonth;
    final netCashflow = incomeMonth - expenseMonth - salariesMonth;

    return Scaffold(
      appBar: AppBar(
        title: Text('التقارير والتصدير ($month) 📊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppTheme.primary),
            tooltip: 'تغيير الشهر المالي',
            onPressed: () async {
              final selected = await MonthPickerDialog.show(
                context,
                initialMonth: provider.selectedMonth,
                allowAllMonths: false,
              );
              if (selected != null && selected.isNotEmpty) {
                await provider.setSelectedMonth(selected);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.fact_check, color: Colors.orange),
            tooltip: 'الحالات الاستثنائية وإغلاق الشهر',
            onPressed: () => ExceptionalCasesDialog.show(context, month),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الملخص المالي لشهر $month',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'الخزنة: ${currencyFormat.format(provider.currentTreasuryBalance)} ج',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        'إجمالي الوارد',
                        '+${currencyFormat.format(incomeMonth)} ج',
                        Colors.greenAccent,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryMetric(
                        'إجمالي المنصرف',
                        '-${currencyFormat.format(expenseMonth)} ج',
                        Colors.redAccent,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryMetric(
                        'مرتبات مدفوعة',
                        '-${currencyFormat.format(salariesMonth)} ج',
                        Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'صافي التدفق المالي للشهر:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      '${netCashflow >= 0 ? "+" : ""}${currencyFormat.format(netCashflow)} ج.م',
                      style: TextStyle(
                        color: netCashflow >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'قائمة التقارير الرئيسية (تصدير Excel / PDF) 📑',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),

          _buildReportTile(
            context: context,
            title: '1. تقرير المرتبات',
            subtitle:
                'كشف مفصل بمرتبات العاملين، الإضافات، الخصومات، وصافي المستحق وحالة الصرف لشهر $month',
            icon: Icons.people_alt_outlined,
            color: Colors.blue.shade700,
            onPdf: () async {
              final salaries = provider.salaries
                  .where((s) => s.month == month)
                  .toList();
              await PdfExportService.printSalariesReport(
                salaries: salaries,
                month: month,
                context: context,
              );
            },
            onExcel: () {
              final salaries = provider.salaries
                  .where((s) => s.month == month)
                  .toList();
              ExcelExportService.exportSalariesCsv(salaries, month);
              _showExportSuccess(context, 'تقرير المرتبات');
            },
          ),
          const SizedBox(height: 10),

          _buildReportTile(
            context: context,
            title: '2. تقرير السلف',
            subtitle: 'كشف بجميع سلف العاملين، المبالغ المسددة، والمتبقية وحالة السداد والخصم التلقائي',
            icon: Icons.request_quote_outlined,
            color: Colors.amber.shade800,
            onPdf: () async {
              await PdfExportService.printTreasuryReport(
                txs: provider.transactions
                    .where(
                      (t) =>
                          t.type == TransactionType.advancePayout ||
                          t.type == TransactionType.advanceRepayment,
                    )
                    .toList(),
                currentBalance: provider.currentTreasuryBalance,
                context: context,
              );
            },
            onExcel: () {
              ExcelExportService.exportAdvancesCsv(provider.advances);
              _showExportSuccess(context, 'تقرير السلف');
            },
          ),
          const SizedBox(height: 10),

          _buildReportTile(
            context: context,
            title: '3. تقرير الوارد',
            subtitle: 'سجل تفصيلي بجميع الإيرادات والتدفقات النقدية الواردة للخزينة والمصادر والتواريخ',
            icon: Icons.arrow_downward,
            color: AppTheme.incomeGreen,
            onPdf: () async {
              await PdfExportService.printTreasuryReport(
                txs: provider.transactions.where((t) => t.isCredit).toList(),
                currentBalance: provider.currentTreasuryBalance,
                context: context,
              );
            },
            onExcel: () {
              ExcelExportService.exportIncomeCsv(provider.incomes);
              _showExportSuccess(context, 'تقرير الوارد');
            },
          ),
          const SizedBox(height: 10),

          _buildReportTile(
            context: context,
            title: '4. تقرير المنصرف',
            subtitle: 'كشف المصروفات والنفقات التشغيلية مصنفة حسب النوع والبيان والمبالغ',
            icon: Icons.arrow_upward,
            color: AppTheme.expenseRed,
            onPdf: () async {
              await PdfExportService.printTreasuryReport(
                txs: provider.transactions.where((t) => !t.isCredit).toList(),
                currentBalance: provider.currentTreasuryBalance,
                context: context,
              );
            },
            onExcel: () {
              ExcelExportService.exportExpensesCsv(provider.expenses);
              _showExportSuccess(context, 'تقرير المنصرف');
            },
          ),
          const SizedBox(height: 10),

          _buildReportTile(
            context: context,
            title: '5. تقرير الخزنة 💰',
            subtitle: 'كشف حساب حركة الخزنة الشامل لجميع العمليات النقدية والرصيد اللحظي',
            icon: Icons.account_balance,
            color: AppTheme.primary,
            onPdf: () async {
              await PdfExportService.printTreasuryReport(
                txs: provider.transactions,
                currentBalance: provider.currentTreasuryBalance,
                context: context,
              );
            },
            onExcel: () {
              ExcelExportService.exportTreasuryCsv(
                provider.transactions,
                provider.currentTreasuryBalance,
              );
              _showExportSuccess(context, 'تقرير حركة الخزنة');
            },
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person_search_outlined,
                          color: Colors.purple.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '6. تقرير حركة عامل معين (كشف حساب)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'اختر عاملاً لاستخراج كشف حساب مالي شامل لجميع مرتباته وسلفه',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _chooseEmployeeForStatement(context, provider),
                    icon: const Icon(Icons.assignment_ind, size: 16),
                    label: const Text('اختيار العامل واستخراج الكشف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          _buildReportTile(
            context: context,
            title: '7. تقرير شهري شامل',
            subtitle:
                'تقرير مالي مجمع يدمج الوارد والمنصرف والمرتبات وحالة الخزنة لشهر $month',
            icon: Icons.calendar_today,
            color: Colors.teal.shade800,
            onPdf: () async {
              await PdfExportService.printTreasuryReport(
                txs: provider.transactions,
                currentBalance: provider.currentTreasuryBalance,
                context: context,
              );
            },
            onExcel: () {
              ExcelExportService.exportSalariesCsv(
                provider.salaries.where((s) => s.month == month).toList(),
                month,
              );
              _showExportSuccess(context, 'التقرير الشهري الشامل');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReportTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPdf,
    required VoidCallback onExcel,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onExcel,
                  icon: const Icon(
                    Icons.table_view,
                    color: Colors.green,
                    size: 16,
                  ),
                  label: const Text('Export Excel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    side: BorderSide(color: Colors.green.shade300),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('طباعة PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExportSuccess(BuildContext context, String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تصدير $reportName بنجاح بصيغة Excel (CSV UTF-8)'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  void _chooseEmployeeForStatement(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text(
            'اختر العامل',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          children: provider.employees.map((emp) {
            return SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(ctx);
                final salaries = provider.getEmployeeSalaries(emp.id);
                final advances = provider.getEmployeeAdvances(emp.id);
                final totalPaid = provider.getEmployeeTotalPaid(emp.id);
                final remainingAdv = provider.getEmployeeRemainingAdvances(
                  emp.id,
                );

                await PdfExportService.printEmployeeStatement(
                  emp: emp,
                  salaries: salaries,
                  advances: advances,
                  totalPaid: totalPaid,
                  remainingAdvances: remainingAdv,
                  context: context,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      emp.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      emp.phone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
