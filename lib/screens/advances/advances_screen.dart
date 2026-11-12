import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../services/excel_export_service.dart';
import 'add_advance_dialog.dart';
import 'repay_advance_dialog.dart';

class AdvancesScreen extends StatelessWidget {
  const AdvancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('yyyy/MM/dd');

    final advances = provider.advances;
    final totalAmount = advances.fold<double>(0, (sum, a) => sum + a.amount);
    final totalPaid = advances.fold<double>(0, (sum, a) => sum + a.paidAmount);
    final totalRemaining = advances.fold<double>(0, (sum, a) => sum + a.remainingAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السلف 🤝'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.green),
            tooltip: 'تصدير السلف (Excel)',
            onPressed: () {
              ExcelExportService.exportAdvancesCsv(advances);
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
        label: const Text('إعطاء سلفة'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
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
            child: advances.isEmpty
                ? const EmptyState(
                    icon: Icons.request_quote_outlined,
                    title: 'لا توجد سلف مسجلة',
                    subtitle: 'اضغط على زر إعطاء سلفة لتسجيل سلفة جديدة للعامل',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: advances.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final adv = advances[i];
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
                                          'تاريخ السلفة: ${dateFormat.format(adv.date)}',
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: Color(0xFF0F172A),
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
                                        ),
                                        child: Text(
                                          isFullyPaid
                                              ? 'مسددة بالكامل'
                                              : (adv.paidAmount > 0
                                                  ? 'مسددة جزئياً'
                                                  : 'مستحقة'),
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
                              const SizedBox(height: 10),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: adv.amount > 0
                                      ? (adv.paidAmount / adv.amount).clamp(0.0, 1.0)
                                      : 1.0,
                                  backgroundColor: Colors.grey.shade200,
                                  color: isFullyPaid
                                      ? Colors.green
                                      : Colors.amber.shade700,
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'المسدد: ${adv.paidAmount.toStringAsFixed(0)} ج  |  المتبقي: ${adv.remainingAmount.toStringAsFixed(0)} ج',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: adv.remainingAmount > 0
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                  if (adv.autoDeductFromSalary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'خصم تلقائي من المرتب',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (adv.notes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'ملاحظات: ${adv.notes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              if (!isFullyPaid) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            RepayAdvanceDialog(advance: adv),
                                      );
                                    },
                                    icon: const Icon(Icons.payments_outlined,
                                        size: 16),
                                    label: const Text('سداد نقدي بالخزنة'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.incomeGreen,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      textStyle: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
