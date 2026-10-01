import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import 'adjust_treasury_dialog.dart';

class TreasuryScreen extends StatelessWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    final balance = provider.currentTreasuryBalance;
    final totalIncome = provider.totalIncomeAllTime;
    final totalExpense = provider.totalExpenseAllTime;
    final totalPaidSalaries = provider.totalPaidSalariesForSelectedMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخزينة الرئيسية 💰'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'طباعة كشف حركة الخزنة (PDF)',
            onPressed: () async {
              await PdfExportService.printTreasuryReport(
                txs: provider.transactions,
                currentBalance: balance,
                context: context,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.green),
            tooltip: 'تصدير حركة الخزنة (Excel)',
            onPressed: () {
              ExcelExportService.exportTreasuryCsv(
                provider.transactions,
                balance,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تصدير كشف حركة الخزنة بنجاح'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الرصيد الفعلي الحالي بالخزنة',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: Colors.white70),
                      tooltip: 'تسوية رصيد الخزنة',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AdjustTreasuryDialog(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${currencyFormat.format(balance)} ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Text(
                      'ج.م',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),

                const Text(
                  'معادلة حركة الخزنة 💡',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildEquationRow('رصيد البداية والتسويات:',
                          '${currencyFormat.format(provider.initialBalance)} ج', Colors.white),
                      const SizedBox(height: 4),
                      _buildEquationRow('+ إجمالي الوارد:',
                          '+ ${currencyFormat.format(totalIncome)} ج', Colors.greenAccent),
                      const SizedBox(height: 4),
                      _buildEquationRow('- إجمالي المنصرف:',
                          '- ${currencyFormat.format(totalExpense)} ج', Colors.redAccent.shade100),
                      const SizedBox(height: 4),
                      _buildEquationRow('- مرتبات الشهر:',
                          '- ${currencyFormat.format(totalPaidSalaries)} ج', Colors.orangeAccent.shade100),
                      const Divider(color: Colors.white30, height: 12),
                      _buildEquationRow('= الرصيد الحالي:',
                          '${currencyFormat.format(balance)} ج.م', Colors.white, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const AdjustTreasuryDialog(
                              isManualMovement: true,
                              isDeposit: true,
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: const Text('إيداع نقدية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const AdjustTreasuryDialog(
                              isManualMovement: true,
                              isDeposit: false,
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        label: const Text('سحب نقدية'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'سجل حركات الخزنة النقدية 📜',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                '${provider.transactions.length} حركة مسجلة',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.transactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final tx = provider.transactions[i];
              final isCredit = tx.isCredit;
              final color = isCredit ? AppTheme.incomeGreen : AppTheme.expenseRed;
              final sign = isCredit ? '+' : '-';

              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tx.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  subtitle: Text(
                    '${dateFormat.format(tx.date)}  •  ${tx.typeLabel}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Text(
                    '$sign ${currencyFormat.format(tx.amount)} ج',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEquationRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isBold ? 14 : 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
