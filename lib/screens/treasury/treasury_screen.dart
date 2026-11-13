import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import '../../widgets/month_picker_dialog.dart';
import 'adjust_treasury_dialog.dart';

class TreasuryScreen extends StatefulWidget {
  const TreasuryScreen({super.key});

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  bool _showAllHistory = false;
  final currencyFormat = NumberFormat('#,##0', 'en_US');
  final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selectedMonth = provider.selectedMonth;

    final balance = provider.currentTreasuryBalance;
    final openingBalance = provider.initialBalance;
    final totalDeposits = provider.totalDepositsForSelectedMonth;
    final totalIncome = provider.totalIncomeForSelectedMonth;
    final totalExpense = provider.totalExpenseForSelectedMonth;
    final totalPaidSalaries = provider.totalPaidSalariesForSelectedMonth;

    final displayedTransactions = _showAllHistory
        ? provider.transactions
        : provider.transactionsForSelectedMonth;

    return Scaffold(
      appBar: AppBar(
        title: Text('خزينة شهر $selectedMonth 💰'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppTheme.primary),
            tooltip: 'تغيير الشهر المالي',
            onPressed: () => _pickMonth(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'طباعة كشف حركة الخزنة (PDF)',
            onPressed: () async {
              await PdfExportService.printTreasuryReport(
                txs: displayedTransactions,
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
                displayedTransactions,
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
          // Month Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'الشهر المالي الحالي: $selectedMonth',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _pickMonth(context, provider),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('تبديل الشهر'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main Treasury Balance Card
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
                    Text(
                      'الرصيد الفعلي لخزينة شهر $selectedMonth',
                      style: const TextStyle(
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
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),

                const Text(
                  'تفاصيل حركة خزينة الشهر 💡',
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
                      _buildEquationRow(
                        'رصيد البداية للشهر:',
                        '${currencyFormat.format(openingBalance)} ج',
                        Colors.white,
                      ),
                      if (totalDeposits > 0) ...[
                        const SizedBox(height: 4),
                        _buildEquationRow(
                          '+ إيداعات نقدية إضافية:',
                          '+ ${currencyFormat.format(totalDeposits)} ج',
                          Colors.cyanAccent,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _buildEquationRow(
                        '+ إجمالي الوارد:',
                        '+ ${currencyFormat.format(totalIncome)} ج',
                        Colors.greenAccent,
                      ),
                      const SizedBox(height: 4),
                      _buildEquationRow(
                        '- إجمالي المنصرف:',
                        '- ${currencyFormat.format(totalExpense)} ج',
                        Colors.redAccent.shade100,
                      ),
                      const SizedBox(height: 4),
                      _buildEquationRow(
                        '- مرتبات مدفوعة للشهر:',
                        '- ${currencyFormat.format(totalPaidSalaries)} ج',
                        Colors.orangeAccent.shade100,
                      ),
                      const Divider(color: Colors.white30, height: 12),
                      _buildEquationRow(
                        '= رصيد الخزنة الحالي:',
                        '${currencyFormat.format(balance)} ج.م',
                        Colors.white,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
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
                      label: const Text('إيداع نقدية بالخزنة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryDark,
                      ),
                    ),
                    OutlinedButton.icon(
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
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AdjustTreasuryDialog(
                            isSetOpeningBalance: true,
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_balance, size: 16),
                      label: const Text('تعيين رصيد البداية'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Transactions Header & Filter Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showAllHistory
                    ? 'سجل حركات الخزنة لجميع الفترات 📜'
                    : 'حركات خزينة شهر $selectedMonth 📜',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('شهر $selectedMonth'),
                    selected: !_showAllHistory,
                    onSelected: (val) => setState(() => _showAllHistory = !val),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('السجل الشامل'),
                    selected: _showAllHistory,
                    onSelected: (val) => setState(() => _showAllHistory = val),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (displayedTransactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _showAllHistory
                      ? 'لا توجد أي حركات خزنة مسجلة في النظام'
                      : 'لا توجد حركات خزنة مسجلة لشهر $selectedMonth بعد',
                  style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo'),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedTransactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final tx = displayedTransactions[i];
                final isCredit = tx.isCredit;
                final color =
                    isCredit ? AppTheme.incomeGreen : AppTheme.expenseRed;
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
                      '${dateFormat.format(tx.date)}  •  ${tx.typeLabel} (شهر ${tx.month})',
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
