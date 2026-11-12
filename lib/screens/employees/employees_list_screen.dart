import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'employee_dialog.dart';
import 'employee_profile_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  String _searchQuery = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    List<Employee> list = provider.employees.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.phone.contains(_searchQuery);
      if (!matchesSearch) return false;

      if (_filter == 'active') return e.isActive;
      if (_filter == 'inactive') return !e.isActive;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('العاملين (${provider.employees.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'إضافة عامل جديد',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const EmployeeDialog(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const EmployeeDialog(),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('إضافة عامل'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث باسم العامل أو رقم الموبايل...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFilterChip('الكل (${provider.employees.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'نشط (${provider.employees.where((e) => e.isActive).length})',
                      'active',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'غير نشط (${provider.employees.where((e) => !e.isActive).length})',
                      'inactive',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'لم يتم العثور على أي عامل',
                    subtitle: 'تأكد من كتابة الاسم أو رقم الموبايل بشكل صحيح',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final emp = list[i];
                      final remAdv = provider.getEmployeeRemainingAdvances(emp.id);

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: emp.isActive
                                ? AppTheme.primary.withValues(alpha: 0.12)
                                : Colors.grey.shade200,
                            foregroundColor: emp.isActive
                                ? AppTheme.primary
                                : Colors.grey.shade600,
                            child: Text(
                              emp.name.isNotEmpty
                                  ? emp.name.trim().split(' ').first[0]
                                  : '؟',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  emp.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: emp.isActive
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: emp.isActive
                                        ? Colors.green.shade200
                                        : Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  emp.isActive ? 'نشط' : 'غير نشط',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: emp.isActive
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined,
                                      size: 13, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    emp.phone,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Icon(Icons.attach_money,
                                      size: 14, color: Colors.teal.shade700),
                                  Text(
                                    'المرتب: ${emp.salary.toStringAsFixed(0)} ج',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              if (remAdv > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 13, color: Colors.amber.shade900),
                                    const SizedBox(width: 4),
                                    Text(
                                      'سلف متبقية: ${remAdv.toStringAsFixed(0)} ج',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_back_ios_new, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EmployeeProfileScreen(employeeId: emp.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppTheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primary : Colors.grey.shade700,
      ),
    );
  }
}
