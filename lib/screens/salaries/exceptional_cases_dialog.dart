import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/advance.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class ExceptionalCasesDialog extends StatelessWidget {
  final String month;

  const ExceptionalCasesDialog({super.key, required this.month});

  static void show(BuildContext context, String month) {
    showDialog(
      context: context,
      builder: (_) => ExceptionalCasesDialog(month: month),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final summary = provider.getExceptionalCasesSummary(month);
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    final unpaidSalaries =
        summary['unpaidSalaries'] as List<Map<String, dynamic>>;
    final totalUnpaidSalary = summary['totalUnpaidSalary'] as double;
    final outstandingAdvances =
        summary['outstandingAdvances'] as List<Advance>;
    final totalOutstandingAdvances =
        summary['totalOutstandingAdvances'] as double;
    final auditLogs = summary['auditLogs'] as List<Map<String, dynamic>>;
    final isClosed = summary['isPeriodClosed'] as bool;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fact_check,
                          color: AppTheme.primary, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'الحالات الاستثنائية وإغلاق شهر $month',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // KPI / Status Overview
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: totalUnpaidSalary > 0
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: totalUnpaidSalary > 0
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مرتبات غير مسددة أو متبقية:',
                            style: TextStyle(fontSize: 11.5, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currencyFormat.format(totalUnpaidSalary)} ج.م',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: totalUnpaidSalary > 0
                                  ? AppTheme.expenseRed
                                  : Colors.green.shade800,
                            ),
                          ),
                          Text(
                            '${unpaidSalaries.length} عمال لم يُصرف لهم بالكامل',
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: totalOutstandingAdvances > 0
                            ? Colors.amber.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: totalOutstandingAdvances > 0
                              ? Colors.amber.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'سلف معلقة / لم تُخصم:',
                            style: TextStyle(fontSize: 11.5, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currencyFormat.format(totalOutstandingAdvances)} ج.م',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: totalOutstandingAdvances > 0
                                  ? Colors.amber.shade900
                                  : Colors.green.shade800,
                            ),
                          ),
                          Text(
                            '${outstandingAdvances.length} سلف غير مستقطعة بالكامل',
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Important Note Banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'قاعدة النظام: السلف غير المخصومة تبقى محفوظة كحالات استثنائية ولا يتم ترحيلها تلقائياً إلى حساب سلف الشهر التالي (كل شهر يبدأ سلفه من الصفر).',
                        style: TextStyle(fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Details Tabs / List
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: AppTheme.primary,
                        tabs: [
                          Tab(text: 'مرتبات متبقية (${unpaidSalaries.length})'),
                          Tab(text: 'سلف معلقة (${outstandingAdvances.length})'),
                          Tab(text: 'سجل التدقيق (${auditLogs.length})'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 1. Unpaid / Partially Paid Salaries
                            unpaidSalaries.isEmpty
                                ? const Center(
                                    child: Text('جميع المرتبات مدفوعة بالكامل لشهر هذا الشهر ✅'),
                                  )
                                : ListView.separated(
                                    itemCount: unpaidSalaries.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (ctx, i) {
                                      final item = unpaidSalaries[i];
                                      final emp = item['employee'];
                                      final unpaidAmt =
                                          item['unpaidAmount'] as double;
                                      final status = item['status'] as String;

                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            emp.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          subtitle: Text(
                                            'الحالة: $status',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          trailing: Text(
                                            'مستحق: ${currencyFormat.format(unpaidAmt)} ج',
                                            style: const TextStyle(
                                              color: AppTheme.expenseRed,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                            // 2. Outstanding Advances
                            outstandingAdvances.isEmpty
                                ? const Center(
                                    child: Text('لا توجد سلف معلقة لشهر هذا الشهر ✅'),
                                  )
                                : ListView.separated(
                                    itemCount: outstandingAdvances.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (ctx, i) {
                                      final adv = outstandingAdvances[i];
                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            adv.employeeName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          subtitle: Text(
                                            'أصل السلفة: ${adv.amount.toStringAsFixed(0)} ج  •  المسدد: ${adv.paidAmount.toStringAsFixed(0)} ج\nملاحظة: ${adv.statusNotes.isNotEmpty ? adv.statusNotes : (adv.notes.isNotEmpty ? adv.notes : "لم يتم الاستقطاع من المرتب")}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'متبقي: ${currencyFormat.format(adv.remainingAmount)} ج',
                                                style: TextStyle(
                                                  color: Colors.amber.shade900,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                              Text(
                                                adv.isOutstanding
                                                    ? 'سلفة معلقة'
                                                    : 'قيد التسوية',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                            // 3. Audit Log
                            auditLogs.isEmpty
                                ? const Center(
                                    child: Text('لا توجد تعديلات تدقيق مسجلة لهذا الشهر'),
                                  )
                                : ListView.separated(
                                    itemCount: auditLogs.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (ctx, i) {
                                      final log = auditLogs[i];
                                      final ts = log['timestamp'] as DateTime;
                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            '${log['employeeName']} - ${log['action']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${dateFormat.format(ts)}\n${log['details']}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
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
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Bottom Actions: Close / Reopen Month
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isClosed
                        ? 'حالة الفترة: مغلقة ومحفوظة 🔒'
                        : 'حالة الفترة: مفتوحة للتعديل 🟢',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isClosed ? Colors.red.shade700 : Colors.green.shade800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (!isClosed)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text('إغلاق شهر $month'),
                            content: const Text(
                              'هل تريد إغلاق واعتماد الشهر المالي؟ سيتم حفظ كشف الحالات الاستثنائية كاملاً في السجلات ولن يؤثر ذلك على تصفير الشهر القادم.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('إلغاء'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('تأكيد الإغلاق'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await provider.closePeriod(month);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم إغلاق شهر $month بنجاح'),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.lock, size: 16),
                      label: const Text('إغلاق واعتماد الشهر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        await provider.reopenPeriod(month);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم إعادة فتح شهر $month للتعديل'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text('إعادة فتح الشهر'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
