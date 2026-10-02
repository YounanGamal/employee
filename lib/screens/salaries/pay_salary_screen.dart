import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/month_picker_dialog.dart';

class PaySalaryScreen extends StatefulWidget {
  final Employee? preselectedEmployee;
  final SalaryRecord? existingRecord;

  const PaySalaryScreen({
    super.key,
    this.preselectedEmployee,
    this.existingRecord,
  });

  @override
  State<PaySalaryScreen> createState() => _PaySalaryScreenState();
}

class _PaySalaryScreenState extends State<PaySalaryScreen> {
  final _formKey = GlobalKey<FormState>();

  Employee? _selectedEmployee;
  late TextEditingController _monthController;
  late TextEditingController _basicSalaryController;
  late TextEditingController _additionsController;
  late TextEditingController _deductionsController;
  late TextEditingController _advancesController;
  late TextEditingController _notesController;

  late DateTime _paymentDate;
  bool _isPaid = true;
  String _paymentMethod = 'كاش';

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();

    if (widget.existingRecord != null) {
      final rec = widget.existingRecord!;
      _selectedEmployee = provider.getEmployeeById(rec.employeeId);
      _monthController = TextEditingController(text: rec.month);
      _paymentDate = rec.paymentDate ?? AppProvider.getDayOneOfMonth(rec.month);
      _basicSalaryController =
          TextEditingController(text: rec.basicSalary.toStringAsFixed(0));
      _additionsController =
          TextEditingController(text: rec.additions.toStringAsFixed(0));
      _deductionsController =
          TextEditingController(text: rec.deductions.toStringAsFixed(0));
      _advancesController =
          TextEditingController(text: rec.advancesDeducted.toStringAsFixed(0));
      _notesController = TextEditingController(text: rec.notes);
      _isPaid = rec.isPaid;
      _paymentMethod = rec.paymentMethod;
    } else {
      _selectedEmployee = widget.preselectedEmployee ??
          (provider.employees.isNotEmpty ? provider.employees.first : null);
      final defaultMonth = provider.selectedMonth;
      _monthController = TextEditingController(text: defaultMonth);
      _paymentDate = AppProvider.getDayOneOfMonth(defaultMonth);

      final initialSalary = _selectedEmployee?.salary ?? 0.0;
      _basicSalaryController =
          TextEditingController(text: initialSalary.toStringAsFixed(0));
      _additionsController = TextEditingController(text: '0');
      _deductionsController = TextEditingController(text: '0');
      _advancesController = TextEditingController(text: '0');
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _basicSalaryController.dispose();
    _additionsController.dispose();
    _deductionsController.dispose();
    _advancesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _basic => double.tryParse(_basicSalaryController.text.trim()) ?? 0.0;
  double get _additions => double.tryParse(_additionsController.text.trim()) ?? 0.0;
  double get _deductions => double.tryParse(_deductionsController.text.trim()) ?? 0.0;
  double get _advances => double.tryParse(_advancesController.text.trim()) ?? 0.0;

  double get _netSalary => (_basic + _additions - _deductions - _advances);

  void _onEmployeeChanged(Employee? emp) {
    if (emp == null) return;
    setState(() {
      _selectedEmployee = emp;
      _basicSalaryController.text = emp.salary.toStringAsFixed(0);
    });
  }

  void _pickSalaryMonth() async {
    final selected = await MonthPickerDialog.show(
      context,
      initialMonth: _monthController.text.trim(),
      allowAllMonths: false,
    );
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _monthController.text = selected;
        _paymentDate = AppProvider.getDayOneOfMonth(selected);
      });
    }
  }

  void _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار العامل المراد صرف مرتبه'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    final record = SalaryRecord(
      id: widget.existingRecord?.id ??
          'sal_${_selectedEmployee!.id}_${_monthController.text.trim()}',
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      month: _monthController.text.trim(),
      basicSalary: _basic,
      additions: _additions,
      deductions: _deductions,
      advancesDeducted: _advances,
      isPaid: _isPaid,
      paymentMethod: _paymentMethod,
      paymentDate: _isPaid ? _paymentDate : null,
      notes: _notesController.text.trim(),
    );

    if (_isPaid) {
      await provider.paySalary(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم صرف مرتب ${_selectedEmployee!.name} بقيمة ${_netSalary.toStringAsFixed(0)} ج وتم الخصم من الخزنة',
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } else {
      await provider.saveUnpaidSalaryRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ بيانات المرتب كـ "غير مدفوع"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pendingAdv = _selectedEmployee != null
        ? provider.getEmployeeRemainingAdvances(_selectedEmployee!.id)
        : 0.0;
    final treasuryBalance = provider.currentTreasuryBalance;
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: const Text('صرف مرتب العامل 💵'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // رصيد الخزنة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.teal.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'رصيد الخزنة المتاح: ${currencyFormat.format(treasuryBalance)} ج.م',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // اختيار العامل
                DropdownButtonFormField<Employee>(
                  initialValue: _selectedEmployee,
                  decoration: const InputDecoration(
                    labelText: 'اختيار العامل *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: provider.employees.map((emp) {
                    return DropdownMenuItem(
                      value: emp,
                      child: Text(
                        '${emp.name} (${emp.salary.toStringAsFixed(0)} ج)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: widget.preselectedEmployee != null
                      ? null
                      : _onEmployeeChanged,
                ),
                const SizedBox(height: 14),

                // شهر المرتب
                TextFormField(
                  controller: _monthController,
                  readOnly: true,
                  onTap: _pickSalaryMonth,
                  decoration: InputDecoration(
                    labelText: 'الشهر المالي المستحق *',
                    hintText: 'اضغط لاختيار الشهر',
                    prefixIcon: const Icon(Icons.calendar_month, color: AppTheme.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit_calendar, color: AppTheme.primary),
                      onPressed: _pickSalaryMonth,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'يرجى اختيار الشهر' : null,
                ),
                const SizedBox(height: 10),

                // بطاقة تاريخ الصرف الافتراضي (يوم 1 في الشهر)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available, color: Colors.blue.shade700, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تاريخ الصرف: ${DateFormat('yyyy/MM/dd').format(_paymentDate)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Colors.blue.shade900,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'تاريخ استحقاق وصرف المرتب: يوم 1 في الشهر (افتراضي)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickPaymentDate,
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('تغيير'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // المرتب الأساسي
                TextFormField(
                  controller: _basicSalaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المرتب الأساسي (ج.م) *',
                    prefixIcon: Icon(Icons.money),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'يرجى إدخال المرتب' : null,
                ),
                const SizedBox(height: 14),

                // إضافات وخصومات
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _additionsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'إضافات ومكافأة (+)',
                          prefixIcon: Icon(Icons.add_circle_outline, color: Colors.green),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _deductionsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'خصومات وجزاءات (-)',
                          prefixIcon: Icon(Icons.remove_circle_outline, color: Colors.red),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // سلف مستقطعة
                TextFormField(
                  controller: _advancesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'سلف مستقطعة من المرتب (-)',
                    prefixIcon: const Icon(Icons.request_quote_outlined, color: Colors.amber),
                    suffixIcon: pendingAdv > 0
                        ? TextButton(
                            onPressed: () {
                              setState(() {
                                _advancesController.text =
                                    pendingAdv.toStringAsFixed(0);
                              });
                            },
                            child: const Text('خصم الكل'),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (pendingAdv > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'لدى العامل سلف متبقية تستحق السداد بقيمة: ${pendingAdv.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // بطاقة صافي المرتب المستحق
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.1),
                        AppTheme.primary.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صافي المرتب المستحق للصرف:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            '${_netSalary.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _netSalary >= 0
                                  ? AppTheme.primaryDark
                                  : Colors.red.shade700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'المعادلة: الأساسي (${_basic.toStringAsFixed(0)}) + إضافي (${_additions.toStringAsFixed(0)}) - خصم (${_deductions.toStringAsFixed(0)}) - سلف (${_advances.toStringAsFixed(0)})',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // حالة الدفع وطريقة الدفع
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isPaid ? 'الحالة: مدفوع' : 'الحالة: غير مدفوع',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: _isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                            Switch(
                              value: _isPaid,
                              activeThumbColor: Colors.green.shade700,
                              onChanged: (val) => setState(() => _isPaid = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'طريقة الدفع',
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'كاش', child: Text('كاش (نقداً)')),
                          DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي')),
                          DropdownMenuItem(value: 'محفظة إلكترونية', child: Text('محفظة')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMethod = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ملاحظات الصرف
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات الصرف (اختياري)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 28),

                // زر التأكيد
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaid ? AppTheme.primary : Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isPaid
                          ? 'تأكيد وصرف المرتب من الخزنة 💰'
                          : 'حفظ كمرتب مستحق غير مدفوع',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

