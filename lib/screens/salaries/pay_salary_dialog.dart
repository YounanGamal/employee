import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class PaySalaryDialog extends StatefulWidget {
  final Employee? preselectedEmployee;
  final SalaryRecord? existingRecord;

  const PaySalaryDialog({
    super.key,
    this.preselectedEmployee,
    this.existingRecord,
  });

  @override
  State<PaySalaryDialog> createState() => _PaySalaryDialogState();
}

class _PaySalaryDialogState extends State<PaySalaryDialog> {
  final _formKey = GlobalKey<FormState>();

  Employee? _selectedEmployee;
  late TextEditingController _monthController;
  late TextEditingController _basicSalaryController;
  late TextEditingController _additionsController;
  late TextEditingController _deductionsController;
  late TextEditingController _advancesController;
  late TextEditingController _notesController;

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
      _monthController = TextEditingController(text: provider.selectedMonth);

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

  double get _basic => double.tryParse(_basicSalaryController.text) ?? 0.0;
  double get _additions => double.tryParse(_additionsController.text) ?? 0.0;
  double get _deductions => double.tryParse(_deductionsController.text) ?? 0.0;
  double get _advances => double.tryParse(_advancesController.text) ?? 0.0;

  double get _netSalary => (_basic + _additions - _deductions - _advances);

  void _onEmployeeChanged(Employee? emp) {
    if (emp == null) return;
    setState(() {
      _selectedEmployee = emp;
      _basicSalaryController.text = emp.salary.toStringAsFixed(0);
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العامل')),
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
      paymentDate: _isPaid ? DateTime.now() : null,
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'صرف مرتب العامل 💵',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

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
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _monthController,
                    decoration: const InputDecoration(
                      labelText: 'الشهر (مثال: 2026-09) *',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'يرجى إدخال الشهر' : null,
                  ),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _additionsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'إضافات (+)',
                            prefixIcon: Icon(Icons.add_circle_outline, color: Colors.green),
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
                            labelText: 'خصومات (-)',
                            prefixIcon: Icon(Icons.remove_circle_outline, color: Colors.red),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _advancesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'سلف مستقطعة (-)',
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
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '⚠️ لدى العامل سلف متبقية بقيمة: ${pendingAdv.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'صافي المرتب المستحق:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          '${_netSalary.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _netSalary >= 0
                                ? AppTheme.primaryDark
                                : Colors.red.shade700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isPaid ? 'حالة: مدفوع' : 'حالة: غير مدفوع',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
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
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات الصرف',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaid ? AppTheme.primary : Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _isPaid
                          ? 'تأكيد وصرف المرتب من الخزنة 💰'
                          : 'حفظ كمرتب مستحق غير مدفوع',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
