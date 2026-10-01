import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'log/operations_log_screen.dart';
import 'income/income_screen.dart';
import 'expenses/expenses_screen.dart';
import 'treasury/treasury_screen.dart';
import 'employees/employees_list_screen.dart';
import 'advances/advances_screen.dart';
import 'reports/reports_screen.dart';
import 'search/quick_search_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width >= 900;

    final List<Widget> screens = [
      DashboardScreen(onNavigateToTab: _navigateToTab),
      const EmployeesListScreen(),
      const TreasuryScreen(),
      const AdvancesScreen(),
      const OperationsLogScreen(),
      const IncomeScreen(),
      const ExpensesScreen(),
      const ReportsScreen(),
    ];

    final navItems = [
      const NavigationItemData(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'لوحة التحكم'),
      const NavigationItemData(icon: Icons.people_outline, activeIcon: Icons.people, label: 'العاملين'),
      const NavigationItemData(icon: Icons.account_balance_outlined, activeIcon: Icons.account_balance, label: 'الخزنة 💰'),
      const NavigationItemData(icon: Icons.request_quote_outlined, activeIcon: Icons.request_quote, label: 'السلف'),
      const NavigationItemData(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'سجل العمليات'),
      const NavigationItemData(icon: Icons.arrow_downward_outlined, activeIcon: Icons.arrow_downward, label: 'الوارد'),
      const NavigationItemData(icon: Icons.arrow_upward_outlined, activeIcon: Icons.arrow_upward, label: 'المنصرف'),
      const NavigationItemData(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'التقارير'),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Material(
              color: Colors.white,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            radius: 18,
                            child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'نظام الخزنة والعاملين',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: navItems.length,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        itemBuilder: (ctx, i) {
                          final item = navItems[i];
                          final isSel = _currentIndex == i;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              dense: true,
                              tileColor: isSel ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              leading: Icon(
                                isSel ? item.activeIcon : item.icon,
                                color: isSel ? AppTheme.primary : Colors.grey.shade700,
                              ),
                              title: Text(
                                item.label,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? AppTheme.primaryDark : Colors.grey.shade800,
                                ),
                              ),
                              trailing: item.badgeCount != null && item.badgeCount! > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningOrange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${item.badgeCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () => setState(() => _currentIndex = i),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('بحث سريع', style: TextStyle(fontFamily: 'Cairo')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuickSearchScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Expanded(child: screens[_currentIndex]),
          ],
        ),
      );
    }

    final bottomNavIndices = [0, 1, 2, 3, 4];
    int bottomBarSelected = bottomNavIndices.indexOf(_currentIndex);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_balance, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'نظام إدارة العاملين والخزنة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    'رصيد الخزنة: ${provider.currentTreasuryBalance.toStringAsFixed(0)} ج',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ...List.generate(navItems.length, (i) {
              final item = navItems[i];
              return ListTile(
                leading: Icon(item.icon, color: _currentIndex == i ? AppTheme.primary : null),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: _currentIndex == i ? FontWeight.bold : FontWeight.normal,
                    color: _currentIndex == i ? AppTheme.primary : null,
                  ),
                ),
                trailing: item.badgeCount != null && item.badgeCount! > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.badgeCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = i);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: const Text('بحث سريع بالاسم والموبايل', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuickSearchScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.amber),
              title: const Text('إعادة ضبط البيانات التجريبية', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () async {
                Navigator.pop(context);
                await provider.resetToSeedData();
              },
            ),
          ],
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomBarSelected != -1 ? bottomBarSelected : 0,
        onDestinationSelected: (val) {
          setState(() {
            _currentIndex = bottomNavIndices[val];
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'العاملين',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'الخزنة 💰',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote),
            label: 'السلف',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'العمليات',
          ),
        ],
      ),
    );
  }
}

class NavigationItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const NavigationItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}
