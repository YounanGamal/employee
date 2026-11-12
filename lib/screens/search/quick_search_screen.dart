import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../employees/employee_profile_screen.dart';

class QuickSearchScreen extends StatefulWidget {
  const QuickSearchScreen({super.key});

  @override
  State<QuickSearchScreen> createState() => _QuickSearchScreenState();
}

class _QuickSearchScreenState extends State<QuickSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final dateFormat = DateFormat('yyyy/MM/dd');
  final currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final results = provider.employees.where((e) {
      if (_query.isEmpty) return true;
      final nameMatches = e.name.toLowerCase().contains(_query.toLowerCase());
      final phoneMatches = e.phone.contains(_query);
      return nameMatches || phoneMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'بحث باسم العامل أو رقم الموبايل...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) => setState(() => _query = val.trim()),
        ),
      ),
      body: results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'لم يتم العثور على أي نتائج تطابق "$_query"',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final emp = results[i];
                final lastSalary = provider.getEmployeeLastPaidSalary(emp.id);
                final remAdvances = provider.getEmployeeRemainingAdvances(emp.id);
                final totalPaid = provider.getEmployeeTotalPaid(emp.id);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeProfileScreen(employeeId: emp.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: emp.isActive
                                  ? AppTheme.primary.withValues(alpha: 0.12)
                                  : Colors.grey.shade200,
                              foregroundColor: emp.isActive
                                  ? AppTheme.primary
                                  : Colors.grey.shade600,
                              radius: 20,
                              child: Text(
                                emp.name.isNotEmpty
                                    ? emp.name.trim().split(' ').first[0]
                                    : '؟',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emp.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  Text(
                                    emp.phone,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_back_ios_new, size: 14),
                          ],
                        ),
                        const Divider(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'المرتب:',
                                '${currencyFormat.format(emp.salary)} ج',
                                Colors.teal.shade800,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'آخر مرتب:',
                                lastSalary != null && lastSalary.paymentDate != null
                                    ? '${dateFormat.format(lastSalary.paymentDate!)} — ${currencyFormat.format(lastSalary.netSalary)} ج'
                                    : 'لا يوجد بعد',
                                Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'السلف:',
                                '${currencyFormat.format(remAdvances)} ج',
                                remAdvances > 0
                                    ? Colors.amber.shade900
                                    : Colors.green.shade800,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'إجمالي المدفوع:',
                                '${currencyFormat.format(totalPaid)} ج',
                                Colors.purple.shade800,
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
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.grey.shade600,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontFamily: 'Cairo',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
