import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/advance.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/month_picker_dialog.dart';
import '../../services/excel_export_service.dart';
import 'add_advance_dialog.dart';
import 'repay_advance_dialog.dart';

class AdvancesScreen extends StatefulWidget {
  const AdvancesScreen({super.key});

  @override
  State<AdvancesScreen> createState() => _AdvancesScreenState();
}

class _AdvancesScreenState extends State<AdvancesScreen> {
  String _viewMode = 'month'; // 'month', 'all', 'outstanding'
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

  void _markAsOutstandingDialog(BuildContext context, Advance adv) {
    final reasonCtrl = TextEditingController(
      text: adv.statusNotes.isNotEmpty
          ? adv.statusNotes
          : 'تعذر استقطاع السلفة من مرتب شهر ${adv.month}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تسجيل كـ سلفة معلقة: ${adv.employeeName}',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيتم تسجيل هذه السلفة كـ "سلفة معلقة / استثنائية". ستبقى محفوظة في السجلات التاريخية ولن تُرحل تلقائياً إلى سلف الشهور القادمة.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'السبب / ملاحظة التعليق *',
                hintText: 'مثلاً: لم يصرف المرتب، تم تأجيل الخصم...',
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
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              final provider = context.read<AppProvider>();
              await provider.markAdvanceAsOutstanding(adv.id, reason: reason);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تسجيل السلفة كـ معلقة بنجاح وحفظها بالسجلات'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              }
            },
            child: const Text('تأكيد وحفظ كـ معلقة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selectedMonth = provider.selectedMonth;

    List<Advance> displayedAdvances;
    if (_viewMode == 'month') {
      displayedAdvances = provider.advancesForSelectedMonth;
    } else if (_viewMode == 'outstanding') {
      displayedAdvances = provider.advances
          .where((a) => a.remainingAmount > 0 || a.isOutstanding)
          .toList();
    } else {
      displayedAdvances = provider.advances;
    }

    final totalAmount =
        displayedAdvances.fold<double>(0, (sum, a) => sum + a.amount);
    final totalPaid =
        displayedAdvances.fold<double>(0, (sum, a) => sum + a.paidAmount);
    final totalRemaining =
        displayedAdvances.fold<double>(0, (sum, a) => sum + a.remainingAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewMode == 'month'
              ? 'سلف شهر $selectedMonth 🤝'
              : (_viewMode == 'outstanding'
                  ? 'السلف المعلقة الاستثنائية'
                  : 'السجل الشامل للسلف'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppTheme.primary),
            tooltip: 'تغيير الشهر المالي',
            onPressed: () => _pickMonth(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.green),
            tooltip: 'تصدير السلف (Excel)',
            onPressed: () {
              ExcelExportService.exportAdvancesCsv(displayedAdvances);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تصدير تقرير السلف بنجاح بصيغة Excel'),
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
            builder: (_) => const AddAdvanceDialog(),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('إعطاء سلفة جديدة'),
      ),
      body: Column(
        children: [
          // Month Selector & Filter Tabs
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
                          const Icon(Icons.calendar_month,
                              size: 18, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'الشهر المالي: $selectedMonth',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              fontFamily: 'Cairo',
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                        ],
                      ),
                    ),
                    Text(
                      'تبدأ السلف من 0 كل شهر 🔄',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('سلف شهر $selectedMonth (${provider.advancesForSelectedMonth.length})'),
                        selected: _viewMode == 'month',
                        onSelected: (val) {
                          if (val) setState(() => _viewMode = 'month');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('السلف المعلقة الاستثنائية'),
                        selected: _viewMode == 'outstanding',
                        onSelected: (val) {
                          if (val) setState(() => _viewMode = 'outstanding');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('السجل التاريخي الشامل (${provider.advances.length})'),
                        selected: _viewMode == 'all',
                        onSelected: (val) {
                          if (val) setState(() => _viewMode = 'all');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Summary Cards
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _buildHeaderCard(
                    title: 'إجمالي السلف',
                    value: '${currencyFormat.format(totalAmount)} ج',
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildHeaderCard(
                    title: 'المسدد',
                    value: '${currencyFormat.format(totalPaid)} ج',
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildHeaderCard(
                    title: 'المتبقي',
                    value: '${currencyFormat.format(totalRemaining)} ج',
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: displayedAdvances.isEmpty
                ? EmptyState(
                    icon: Icons.request_quote_outlined,
                    title: _viewMode == 'month'
                        ? 'لا توجد سلف مسجلة لشهر $selectedMonth'
                        : 'لا توجد سلف مسجلة في هذا العرض',
                    subtitle: _viewMode == 'month'
                        ? 'يبدأ كل شهر برصيد سلف 0 ج.م تلقائياً. اضغط "إعطاء سلفة جديدة" لتسجيل سلفة لهذا الشهر.'
                        : 'جميع السلف مسددة ومغلقة ولا توجد سلف معلقة.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedAdvances.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final adv = displayedAdvances[i];
                      final isFullyPaid = adv.isFullyPaid;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isFullyPaid
                                        ? Colors.green.shade50
                                        : Colors.amber.shade50,
                                    child: Icon(
                                      isFullyPaid
                                          ? Icons.check
                                          : Icons.hourglass_bottom,
                                      color: isFullyPaid
                                          ? Colors.green.shade700
                                          : Colors.amber.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          adv.employeeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        Text(
                                          'تاريخ السلفة: ${dateFormat.format(adv.date)}  •  شهر: ${adv.month}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${currencyFormat.format(adv.amount)} ج',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isFullyPaid
                                              ? Colors.green.shade50
                                              : Colors.amber.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isFullyPaid
                                                ? Colors.green.shade300
                                                : Colors.amber.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          isFullyPaid
                                              ? 'مسددة بالكامل'
                                              : (adv.isOutstanding
                                                  ? 'سلفة معلقة'
                                                  : 'متبقي ${currencyFormat.format(adv.remainingAmount)} ج'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isFullyPaid
                                                ? Colors.green.shade800
                                                : Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (adv.notes.isNotEmpty ||
                                  adv.statusNotes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  adv.statusNotes.isNotEmpty
                                      ? 'ملاحظة التعليق: ${adv.statusNotes}'
                                      : 'ملاحظات: ${adv.notes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'المسدد: ${currencyFormat.format(adv.paidAmount)} ج',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '|  المتبقي: ${currencyFormat.format(adv.remainingAmount)} ج',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: adv.remainingAmount > 0
                                              ? AppTheme.expenseRed
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (!isFullyPaid) ...[
                                        if (!adv.isOutstanding)
                                          TextButton.icon(
                                            onPressed: () =>
                                                _markAsOutstandingDialog(
                                                    context, adv),
                                            icon: const Icon(
                                                Icons.bookmark_add_outlined,
                                                size: 15),
                                            label: const Text('تعليق السلفة'),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.amber.shade900,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                          ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => RepayAdvanceDialog(
                                                  advance: adv),
                                            );
                                          },
                                          icon: const Icon(Icons.payment,
                                              size: 14),
                                          label: const Text('سداد مباشر'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                          ),
                                        ),
                                      ],
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

  Widget _buildHeaderCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
