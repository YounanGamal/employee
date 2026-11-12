import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/treasury_transaction.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../services/excel_export_service.dart';
import '../../services/pdf_export_service.dart';

class OperationsLogScreen extends StatefulWidget {
  const OperationsLogScreen({super.key});

  @override
  State<OperationsLogScreen> createState() => _OperationsLogScreenState();
}

class _OperationsLogScreenState extends State<OperationsLogScreen> {
  String _selectedType = 'all';
  String _searchQuery = '';
  DateTime? _selectedDate;

  final currencyFormat = NumberFormat('#,##0', 'en_US');
  final dateFormat = DateFormat('dd/MM');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final transactions = provider.transactions.where((t) {
      if (_selectedType == 'income' && t.type != TransactionType.income) return false;
      if (_selectedType == 'expense' && t.type != TransactionType.expense) return false;
      if (_selectedType == 'salary' && t.type != TransactionType.salary) return false;
      if (_selectedType == 'advance' &&
          t.type != TransactionType.advancePayout &&
          t.type != TransactionType.advanceRepayment) {
        return false;
      }

      if (_selectedDate != null) {
        if (t.date.year != _selectedDate!.year ||
            t.date.month != _selectedDate!.month ||
            t.date.day != _selectedDate!.day) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final matches = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.notes.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matches) return false;
      }

      return true;
    }).toList();

    final totalCredit = transactions
        .where((t) => t.isCredit)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalDebit = transactions
        .where((t) => !t.isCredit)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العمليات 📝'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'طباعة سجل العمليات (PDF)',
            onPressed: () async {
              await PdfExportService.printTreasuryReport(
                txs: transactions,
                currentBalance: provider.currentTreasuryBalance,
                context: context,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.green),
            tooltip: 'تصدير سجل العمليات (Excel)',
            onPressed: () {
              ExcelExportService.exportTreasuryCsv(
                transactions,
                provider.currentTreasuryBalance,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تصدير سجل العمليات بصيغة Excel بنجاح'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'بحث في سجل الحركات...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          isDense: true,
                        ),
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        color: _selectedDate != null
                            ? AppTheme.primary
                            : Colors.grey.shade600,
                      ),
                      tooltip: _selectedDate != null
                          ? 'إلغاء فلتر التاريخ'
                          : 'فلترة بالتاريخ',
                      onPressed: () async {
                        if (_selectedDate != null) {
                          setState(() => _selectedDate = null);
                        } else {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        }
                      },
                    ),
                  ],
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'مفلتر بالتاريخ: ${DateFormat('yyyy/MM/dd').format(_selectedDate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() => _selectedDate = null),
                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('الكل', 'all'),
                      const SizedBox(width: 6),
                      _buildChip('وارد (+)', 'income', color: AppTheme.incomeGreen),
                      const SizedBox(width: 6),
                      _buildChip('مصروف (-)', 'expense', color: AppTheme.expenseRed),
                      const SizedBox(width: 6),
                      _buildChip('مرتبات (-)', 'salary', color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      _buildChip('سلف', 'advance', color: Colors.amber.shade800),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عدد العمليات: ${transactions.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Row(
                  children: [
                    Text(
                      '+${currencyFormat.format(totalCredit)} ج',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.incomeGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '-${currencyFormat.format(totalDebit)} ج',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.expenseRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: transactions.isEmpty
                ? const EmptyState(
                    icon: Icons.history,
                    title: 'لا توجد حركات مسجلة',
                    subtitle: 'تأكد من شروط الفلترة أو قم بتسجيل عمليات جديدة',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final tx = transactions[i];
                      final isCredit = tx.isCredit;
                      final sign = isCredit ? '+' : '-';
                      final color =
                          isCredit ? AppTheme.incomeGreen : AppTheme.expenseRed;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dateFormat.format(tx.date),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(tx.date),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            tx.typeLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tx.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              fontFamily: 'Cairo',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tx.notes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        tx.notes,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$sign ${currencyFormat.format(tx.amount)} ج',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  Text(
                                    isCredit ? 'إيداع خزينة' : 'صرف نقدي',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.grey.shade500,
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

  Widget _buildChip(String title, String key, {Color? color}) {
    final isSel = _selectedType == key;
    return ChoiceChip(
      label: Text(title),
      selected: isSel,
      onSelected: (_) => setState(() => _selectedType = key),
      selectedColor: (color ?? AppTheme.primary).withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel ? (color ?? AppTheme.primary) : Colors.grey.shade700,
      ),
    );
  }
}
