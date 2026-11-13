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
  late TextEditingController _paymentAmountController;
  late TextEditingController _notesController;
  late TextEditingController _auditReasonController;

  late DateTime _paymentDate;
  String _payMode = 'full'; // 'full', 'partial', 'unpaid'
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
      _auditReasonController = TextEditingController();

      if (rec.isFullyPaid) {
        _payMode = 'full';
        _paymentAmountController =
            TextEditingController(text: rec.remainingUnpaidSalary.toStringAsFixed(0));
      } else if (rec.isPartiallyPaid) {
        _payMode = 'partial';
        _paymentAmountController =
            TextEditingController(text: rec.remainingUnpaidSalary.toStringAsFixed(0));
      } else {
        _payMode = 'unpaid';
        _paymentAmountController = TextEditingController(text: '0');
      }
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

      // Auto-fill this month's advances ONLY (starts at 0 in new month)
      final thisMonthAdv = _selectedEmployee != null
          ? provider.getEmployeeRemainingAdvances(_selectedEmployee!.id,
              month: defaultMonth)
          : 0.0;
      _advancesController =
          TextEditingController(text: thisMonthAdv.toStringAsFixed(0));

      final initialNet = initialSalary - thisMonthAdv;
      _paymentAmountController =
          TextEditingController(text: initialNet > 0 ? initialNet.toStringAsFixed(0) : '0');
      _notesController = TextEditingController();
      _auditReasonController = TextEditingController();
      _payMode = 'full';
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _basicSalaryController.dispose();
    _additionsController.dispose();
    _deductionsController.dispose();
    _advancesController.dispose();
    _paymentAmountController.dispose();
    _notesController.dispose();
    _auditReasonController.dispose();
    super.dispose();
  }

  double get _basic =>
      double.tryParse(_basicSalaryController.text.trim()) ?? 0.0;
  double get _additions =>
      double.tryParse(_additionsController.text.trim()) ?? 0.0;
  double get _deductions =>
      double.tryParse(_deductionsController.text.trim()) ?? 0.0;
  double get _advances =>
      double.tryParse(_advancesController.text.trim()) ?? 0.0;

  double get _netSalary => (_basic + _additions - _deductions - _advances);

  double get _alreadyPaid => widget.existingRecord?.paidAmount ?? 0.0;
  double get _remainingNeeded =>
      (_netSalary - _alreadyPaid).clamp(0.0, double.infinity);

  void _onEmployeeChanged(Employee? emp) {
    if (emp == null) return;
    final provider = context.read<AppProvider>();
    final month = _monthController.text.trim();
    final thisMonthAdv =
        provider.getEmployeeRemainingAdvances(emp.id, month: month);

    setState(() {
      _selectedEmployee = emp;
      _basicSalaryController.text = emp.salary.toStringAsFixed(0);
      _advancesController.text = thisMonthAdv.toStringAsFixed(0);
      final net = emp.salary - thisMonthAdv;
      if (_payMode == 'full') {
        _paymentAmountController.text =
            net > 0 ? net.toStringAsFixed(0) : '0';
      }
    });
  }

  void _pickSalaryMonth() async {
    final selected = await MonthPickerDialog.show(
      context,
      initialMonth: _monthController.text.trim(),
      allowAllMonths: false,
    );
    if (selected != null && selected.isNotEmpty) {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      final empId = _selectedEmployee?.id;
      final thisMonthAdv = empId != null
          ? provider.getEmployeeRemainingAdvances(empId, month: selected)
          : 0.0;

      setState(() {
        _monthController.text = selected;
        _paymentDate = AppProvider.getDayOneOfMonth(selected);
        _advancesController.text = thisMonthAdv.toStringAsFixed(0);
        if (_payMode == 'full') {
          final net = _basic + _additions - _deductions - thisMonthAdv;
          _paymentAmountController.text =
              net > 0 ? net.toStringAsFixed(0) : '0';
        }
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
          content: Text('يرجى اختيار العامل المراد تسجيل مرتبه'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final month = _monthController.text.trim();

    double disburseAmount = 0.0;
    if (_payMode == 'full') {
      disburseAmount = _remainingNeeded;
    } else if (_payMode == 'partial') {
      disburseAmount =
          double.tryParse(_paymentAmountController.text.trim()) ?? 0.0;
    }

    final baseRecord = SalaryRecord(
      id: widget.existingRecord?.id ?? 'sal_${_selectedEmployee!.id}_$month',
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      month: month,
      basicSalary: _basic,
      additions: _additions,
      deductions: _deductions,
      advancesDeducted: _advances,
      paidAmount: _alreadyPaid,
      payments: widget.existingRecord?.payments ?? [],
      auditLog: widget.existingRecord?.auditLog ?? [],
      paymentMethod: _paymentMethod,
      paymentDate: _payMode != 'unpaid' ? _paymentDate : null,
      notes: _notesController.text.trim(),
    );

    // If an existing record is being edited and an audit reason was provided
    if (widget.existingRecord != null &&
        _auditReasonController.text.trim().isNotEmpty) {
      await provider.recordSalaryCorrection(
        recordId: baseRecord.id,
        newBasicSalary: _basic,
        newAdditions: _additions,
        newDeductions: _deductions,
        newAdvancesDeducted: _advances,
        auditReason: _auditReasonController.text.trim(),
      );
    }

    if (_payMode == 'unpaid' || disburseAmount <= 0) {
      await provider.saveUnpaidSalaryRecord(baseRecord);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ بيانات المرتب بنجاح كـ "غير مدفوع" دون خصم من الخزنة'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      await provider.paySalary(
        salary: baseRecord,
        paymentAmount: disburseAmount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم صرف ${disburseAmount.toStringAsFixed(0)} ج للموظف ${_selectedEmployee!.name} وتم الخصم من خزينة شهر $month',
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentMonth = _monthController.text.trim();

    // Remaining advances strictly for THIS month
    final thisMonthAdv = _selectedEmployee != null
        ? provider.getEmployeeRemainingAdvances(_selectedEmployee!.id,
            month: currentMonth)
        : 0.0;

    // Outstanding historical advances from prior months
    final historicalAdv = _selectedEmployee != null
        ? provider.getEmployeeOutstandingHistoricalAdvances(
            _selectedEmployee!.id,
            upToMonth: currentMonth)
        : 0.0;

    final treasuryBalance =
        provider.getTreasuryBalanceForMonth(currentMonth);
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecord != null
            ? 'تعديل وصرف مرتب العامل'
            : 'تسجيل وصرف مرتب العامل 💵'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Month & Treasury Banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              color: Colors.teal.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'خزينة شهر $currentMonth: ${currencyFormat.format(treasuryBalance)} ج',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _pickSalaryMonth,
                        icon: const Icon(Icons.edit_calendar, size: 16),
                        label: Text('شهر: $currentMonth'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Employee Selection
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
                        '${emp.name} (أساسي الملف: ${emp.salary.toStringAsFixed(0)} ج)',
                      ),
                    );
                  }).toList(),
                  onChanged: widget.existingRecord != null
                      ? null
                      : _onEmployeeChanged,
                ),
                const SizedBox(height: 14),

                // Historical advances warning if any
                if (historicalAdv > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '💡 تنبيه: للعامل سلف معلقة سابقة من شهور ماضية بقيمة ${currencyFormat.format(historicalAdv)} ج.م. حسب قواعد النظام لا يتم خصمها تلقائياً من سلف شهر $currentMonth (سلف هذا الشهر تبدأ من الصفر).',
                            style: const TextStyle(fontSize: 11.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Basic Salary for this month (Requirement #4)
                TextFormField(
                  controller: _basicSalaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المرتب الأساسي لشهر هذا الشهر (ج.م) *',
                    hintText: 'أدخل المرتب المستحق لهذا الشهر تحديداً',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال المرتب الأساسي';
                    final n = double.tryParse(v.trim());
                    if (n == null || n < 0) return 'مبلغ غير صالح';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),

                // Additions & Deductions
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _additionsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'إضافي ومكافآت (+)',
                          prefixIcon: Icon(Icons.add_circle_outline,
                              color: Colors.green),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _deductionsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'خصومات وجزاءات (-)',
                          prefixIcon: Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Advances for this month
                TextFormField(
                  controller: _advancesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'استقطاع سلف شهر $currentMonth (-)',
                    hintText: 'سلف الشهر الحالي المتبقية: ${thisMonthAdv.toStringAsFixed(0)} ج',
                    prefixIcon:
                        const Icon(Icons.money_off, color: Colors.amber),
                    suffixIcon: thisMonthAdv > 0
                        ? TextButton(
                            onPressed: () {
                              _advancesController.text =
                                  thisMonthAdv.toStringAsFixed(0);
                              setState(() {});
                            },
                            child: const Text('خصم كل السلفة'),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),

                // Calculation Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صافي المرتب المستحق للشهر:'),
                          Text(
                            '${currencyFormat.format(_netSalary)} ج.م',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      if (_alreadyPaid > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المبلغ المسدد سابقاً:'),
                            Text(
                              '${currencyFormat.format(_alreadyPaid)} ج.م',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المتبقي المطلوب صرفه:'),
                            Text(
                              '${currencyFormat.format(_remainingNeeded)} ج.م',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.expenseRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Status & Partial Payment Option (Requirement #6)
                const Text(
                  'طريقة وخيار الصرف:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('صرف كامل المستحق'),
                        selected: _payMode == 'full',
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _payMode = 'full';
                              _paymentAmountController.text =
                                  _remainingNeeded.toStringAsFixed(0);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('صرف جزئي (مبلغ محدد)'),
                        selected: _payMode == 'partial',
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _payMode = 'partial';
                              _paymentAmountController.text =
                                  (_remainingNeeded / 2).toStringAsFixed(0);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('تسجيل استحقاق فقط'),
                        selected: _payMode == 'unpaid',
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _payMode = 'unpaid';
                              _paymentAmountController.text = '0';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_payMode == 'partial') ...[
                  TextFormField(
                    controller: _paymentAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ المدفوع فعلياً الآن (ج.م) *',
                      hintText: 'الحد الأقصى: ${_remainingNeeded.toStringAsFixed(0)} ج',
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      if (_payMode != 'partial') return null;
                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ المدفوع';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'مبلغ غير صالح';
                      if (n > _remainingNeeded) {
                        return 'لا يمكن أن يتجاوز المبلغ المتبقي (${_remainingNeeded.toStringAsFixed(0)} ج)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                if (_payMode != 'unpaid') ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickPaymentDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'تاريخ الصرف',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(dateFormat.format(_paymentDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'طريقة الدفع',
                            prefixIcon: Icon(Icons.payment),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'كاش', child: Text('كاش')),
                            DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي')),
                            DropdownMenuItem(value: 'فودافون كاش / محفظة', child: Text('محفظة إلكترونية')),
                          ],
                          onChanged: (val) =>
                              setState(() => _paymentMethod = val ?? 'كاش'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Audit Reason (If editing existing record)
                if (widget.existingRecord != null) ...[
                  TextFormField(
                    controller: _auditReasonController,
                    decoration: const InputDecoration(
                      labelText: 'سبب التعديل / ملاحظة التدقيق المالي',
                      hintText: 'سجل سبباً لتعديل البيانات في سجل التدقيق المالي',
                      prefixIcon: Icon(Icons.history_edu),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات عامة',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _payMode == 'unpaid'
                        ? Colors.orange.shade800
                        : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _payMode == 'unpaid'
                        ? 'حفظ السجل كـ غير مدفوع'
                        : (_payMode == 'partial'
                            ? 'تأكيد صرف الدفعة الجزئية والخصم من الخزنة'
                            : 'تأكيد الصرف الكامل والخصم من الخزنة'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
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
