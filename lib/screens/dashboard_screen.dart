import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_banner.dart';
import 'employees/employee_dialog.dart';
import 'salaries/pay_salary_screen.dart';
import 'advances/add_advance_dialog.dart';
import 'income/add_income_dialog.dart';
import 'expenses/add_expense_screen.dart';
import 'treasury/adjust_treasury_dialog.dart';
import 'search/quick_search_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('dd/MM');

    final treasuryBalance = provider.currentTreasuryBalance;
    final totalIncome = provider.totalIncomeForSelectedMonth;
    final totalExpense = provider.totalExpenseForSelectedMonth;
    final paidSalaries = provider.totalPaidSalariesForSelectedMonth;
    final totalEmployees = provider.totalEmployeesCount;
    final paidEmployees = provider.paidEmployeesCountForSelectedMonth;
    final unpaidEmployees = provider.unpaidEmployeesCountForSelectedMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: AppTheme.primary, size: 28),
            SizedBox(width: 10),
            Text('نظام إدارة العاملين والخزنة'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث سريع بالاسم أو الموبايل',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuickSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة ضبط البيانات التجريبية',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('إعادة ضبط البيانات'),
                  content: const Text(
                    'هل تريد إعادة ضبط بيانات البرنامج إلى الأرقام والبيانات التجريبية الافتراضية؟',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('إعادة ضبط'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await provider.resetToSeedData();
              }
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => await provider.init(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              size: 18, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'الشهر المالي: ${provider.selectedMonth}',
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
                        icon: const Icon(Icons.edit_calendar, size: 16),
                        label: const Text('تغيير الشهر'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (unpaidEmployees > 0) ...[
                    AlertBanner(
                      title: '⚠️ تنبيه المرتبات المستحقة',
                      message:
                          '$unpaidEmployees عمال لم يتم صرف مرتباتهم لشهر سبتمبر (${provider.selectedMonth}).',
                      buttonText: 'صرف المرتبات',
                      onAction: () {
                        if (onNavigateToTab != null) {
                          onNavigateToTab!(1);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
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
                            const Row(
                              children: [
                                Text(
                                  '💰 رصيد الخزنة الحالي',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'الخزينة الرئيسية',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${currencyFormat.format(treasuryBalance)} ',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const Text(
                              'ج.م',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'الرصيد = البداية + الوارد - المنصرف - المرتبات - السلف',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
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
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('إيداع نقدي'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryDark,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                              icon: const Icon(Icons.remove, size: 16),
                              label: const Text('سحب نقدي'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const AdjustTreasuryDialog(
                                    isManualMovement: false,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.tune, color: Colors.white70),
                              tooltip: 'تسوية رصيد الخزنة',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'المؤشرات المالية لشهر سبتمبر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      StatCard(
                        title: 'رصيد الخزنة',
                        value: '${currencyFormat.format(treasuryBalance)} ج',
                        icon: Icons.account_balance_wallet,
                        color: AppTheme.primary,
                        onTap: () {
                          if (onNavigateToTab != null) onNavigateToTab!(5);
                        },
                      ),
                      StatCard(
                        title: 'إجمالي الوارد',
                        value: '${currencyFormat.format(totalIncome)} ج',
                        icon: Icons.arrow_downward_rounded,
                        color: AppTheme.incomeGreen,
                        subtitle: '+ تدفقات نقدية',
                        onTap: () {
                          if (onNavigateToTab != null) onNavigateToTab!(3);
                        },
                      ),
                      StatCard(
                        title: 'إجمالي المنصرف',
                        value: '${currencyFormat.format(totalExpense)} ج',
                        icon: Icons.arrow_upward_rounded,
                        color: AppTheme.expenseRed,
                        subtitle: '- نفقات ومصروفات',
                        onTap: () {
                          if (onNavigateToTab != null) onNavigateToTab!(4);
                        },
                      ),
                      StatCard(
                        title: 'مرتبات الشهر',
                        value: '${currencyFormat.format(paidSalaries)} ج',
                        icon: Icons.people_outline,
                        color: Colors.blue.shade700,
                        subtitle: 'المدفوع نقداً',
                        onTap: () {
                          if (onNavigateToTab != null) onNavigateToTab!(1);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'إحصائيات القوى العاملة والمرتبات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'عدد العاملين',
                          value: '$totalEmployees',
                          subtitle: 'موظف مسجل',
                          icon: Icons.badge_outlined,
                          color: const Color(0xFF334155),
                          onTap: () {
                            if (onNavigateToTab != null) onNavigateToTab!(6);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'مرتبات مدفوعة',
                          value: '$paidEmployees',
                          subtitle: 'تم الصرف',
                          icon: Icons.check_circle_outline,
                          color: Colors.green.shade700,
                          onTap: () {
                            if (onNavigateToTab != null) onNavigateToTab!(1);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'مرتبات متبقية',
                          value: '$unpaidEmployees',
                          subtitle: 'مستحق الصرف',
                          icon: Icons.pending_actions_outlined,
                          color: AppTheme.warningOrange,
                          onTap: () {
                            if (onNavigateToTab != null) onNavigateToTab!(1);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'إجراءات سريعة ⚡',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickActionBtn(
                          context: context,
                          label: 'إضافة وارد',
                          icon: Icons.arrow_downward,
                          color: AppTheme.incomeGreen,
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const AddIncomeDialog(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionBtn(
                          context: context,
                          label: 'تسجيل منصرف',
                          icon: Icons.arrow_upward,
                          color: AppTheme.expenseRed,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionBtn(
                          context: context,
                          label: 'صرف مرتب',
                          icon: Icons.payments_outlined,
                          color: Colors.blue.shade700,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaySalaryScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionBtn(
                          context: context,
                          label: 'سلفة جديدة',
                          icon: Icons.request_quote_outlined,
                          color: Colors.amber.shade800,
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const AddAdvanceDialog(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionBtn(
                          context: context,
                          label: 'إضافة عامل',
                          icon: Icons.person_add_alt_1_outlined,
                          color: AppTheme.primary,
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const EmployeeDialog(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'سجل العمليات الأحدث 📝',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (onNavigateToTab != null) onNavigateToTab!(2);
                        },
                        child: const Text('عرض كل العمليات'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.transactions.take(6).length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final tx = provider.transactions[i];
                        final sign = tx.isCredit ? '+' : '-';
                        final color = tx.isCredit
                            ? AppTheme.incomeGreen
                            : AppTheme.expenseRed;

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(
                              tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                              color: color,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            tx.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          subtitle: Text(
                            '${dateFormat.format(tx.date)}  •  ${tx.typeLabel}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Text(
                            '$sign ${currencyFormat.format(tx.amount)} ج',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionBtn({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  void _pickMonth(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        final months = [
          '2026-09',
          '2026-08',
          '2026-07',
          '2026-06',
          '2026-05',
          '2026-04',
        ];
        return SimpleDialog(
          title: const Text('اختيار الشهر المالي', style: TextStyle(fontFamily: 'Cairo')),
          children: months.map((m) {
            return SimpleDialogOption(
              onPressed: () {
                provider.setSelectedMonth(m);
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m,
                      style: TextStyle(
                        fontWeight: provider.selectedMonth == m
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: provider.selectedMonth == m
                            ? AppTheme.primary
                            : Colors.black87,
                      ),
                    ),
                    if (provider.selectedMonth == m)
                      const Icon(Icons.check, color: AppTheme.primary, size: 18),
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
