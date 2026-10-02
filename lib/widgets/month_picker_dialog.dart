import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class MonthPickerDialog extends StatefulWidget {
  final String initialMonth;
  final bool allowAllMonths;

  const MonthPickerDialog({
    super.key,
    required this.initialMonth,
    this.allowAllMonths = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String initialMonth,
    bool allowAllMonths = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => MonthPickerDialog(
        initialMonth: initialMonth,
        allowAllMonths: allowAllMonths,
      ),
    );
  }

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonthNum;
  late bool _isAllSelected;

  static const List<Map<String, dynamic>> _months = [
    {'num': 1, 'name': 'يناير', 'code': '01'},
    {'num': 2, 'name': 'فبراير', 'code': '02'},
    {'num': 3, 'name': 'مارس', 'code': '03'},
    {'num': 4, 'name': 'أبريل', 'code': '04'},
    {'num': 5, 'name': 'مايو', 'code': '05'},
    {'num': 6, 'name': 'يونيو', 'code': '06'},
    {'num': 7, 'name': 'يوليو', 'code': '07'},
    {'num': 8, 'name': 'أغسطس', 'code': '08'},
    {'num': 9, 'name': 'سبتمبر', 'code': '09'},
    {'num': 10, 'name': 'أكتوبر', 'code': '10'},
    {'num': 11, 'name': 'نوفمبر', 'code': '11'},
    {'num': 12, 'name': 'ديسمبر', 'code': '12'},
  ];

  @override
  void initState() {
    super.initState();
    _isAllSelected = widget.initialMonth == 'all';
    final now = DateTime.now();

    if (_isAllSelected) {
      _selectedYear = now.year;
      _selectedMonthNum = now.month;
    } else {
      try {
        final parts = widget.initialMonth.split('-');
        _selectedYear = int.parse(parts[0]);
        _selectedMonthNum = int.parse(parts[1]);
      } catch (_) {
        _selectedYear = now.year;
        _selectedMonthNum = now.month;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentRealYear = now.year;
    final currentRealMonth = now.month;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: AppTheme.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'اختيار الشهر المالي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Year Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 24),
                      tooltip: 'السنة السابقة',
                      onPressed: () {
                        setState(() {
                          _selectedYear--;
                          _isAllSelected = false;
                        });
                      },
                    ),
                    InkWell(
                      onTap: _showYearPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          children: [
                            Text(
                              '$_selectedYear',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 24),
                      tooltip: 'السنة القادمة',
                      onPressed: () {
                        setState(() {
                          _selectedYear++;
                          _isAllSelected = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 12 Months Grid (3 columns x 4 rows)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.1,
                ),
                itemBuilder: (context, index) {
                  final m = _months[index];
                  final monthNum = m['num'] as int;
                  final monthName = m['name'] as String;
                  final monthCode = m['code'] as String;

                  final isSelected = !_isAllSelected &&
                      monthNum == _selectedMonthNum &&
                      _selectedYear == (widget.initialMonth.isNotEmpty && widget.initialMonth.contains('-')
                          ? int.tryParse(widget.initialMonth.split('-')[0]) ?? _selectedYear
                          : _selectedYear);

                  final isCurrentRealMonth =
                      monthNum == currentRealMonth && _selectedYear == currentRealYear;

                  return InkWell(
                    onTap: () {
                      final result = '$_selectedYear-$monthCode';
                      Navigator.pop(context, result);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : (isCurrentRealMonth
                                ? AppTheme.primary.withValues(alpha: 0.08)
                                : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : (isCurrentRealMonth
                                  ? AppTheme.primary.withValues(alpha: 0.5)
                                  : Colors.grey.shade300),
                          width: isSelected || isCurrentRealMonth ? 1.5 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.check, color: Colors.white, size: 14),
                            ),
                          Text(
                            '$monthCode - $monthName',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: isSelected || isCurrentRealMonth
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isCurrentRealMonth
                                      ? AppTheme.primary
                                      : Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Bottom Actions (Current month & All months option)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final nowCode = DateFormat('yyyy-MM').format(DateTime.now());
                        Navigator.pop(context, nowCode);
                      },
                      icon: const Icon(Icons.today, size: 16),
                      label: const Text('الشهر الحالي'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  if (widget.allowAllMonths) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, 'all'),
                        icon: const Icon(Icons.all_inclusive, size: 16),
                        label: const Text('جميع الشهور'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAllSelected
                              ? AppTheme.primary
                              : Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showYearPicker() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final years = List.generate(16, (i) => 2020 + i);
        return SimpleDialog(
          title: const Text('اختيار السنة', style: TextStyle(fontFamily: 'Cairo')),
          children: years.map((y) {
            final isY = y == _selectedYear;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, y),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$y',
                      style: TextStyle(
                        fontWeight: isY ? FontWeight.bold : FontWeight.normal,
                        color: isY ? AppTheme.primary : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    if (isY)
                      const Icon(Icons.check, color: AppTheme.primary, size: 18),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedYear = selected);
    }
  }
}
