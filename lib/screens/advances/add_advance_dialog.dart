import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../models/advance.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class AddAdvanceDialog extends StatefulWidget {
  final Employee? preselectedEmployee;

  const AddAdvanceDialog({super.key, this.preselectedEmployee});

  @override
  State<AddAdvanceDialog> createState() => _AddAdvanceDialogState();
}

class _AddAdvanceDialogState extends State<AddAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();

  Employee? _selectedEmployee;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  DateTime _date = DateTime.now();
  bool _autoDeduct = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _selectedEmployee = widget.preselectedEmployee ??
        (provider.employees.isNotEmpty ? provider.employees.first : null);
    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العامل')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final provider = context.read<AppProvider>();
    final advanceMonth = DateFormat('yyyy-MM').format(_date);

    final advance = Advance(
      id: 'adv_${DateTime.now().millisecondsSinceEpoch}',
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      amount: amount,
      date: _date,
      month: advanceMonth,
      paidAmount: 0.0,
      autoDeductFromSalary: _autoDeduct,
      notes: _notesController.text.trim(),
    );

    await provider.addAdvance(advance);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل سلفة لشهر $advanceMonth للموظف ${_selectedEmployee!.name} بقيمة ${amount.toStringAsFixed(0)} ج وتم الخصم من الخزنة',
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final advanceMonth = DateFormat('yyyy-MM').format(_date);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                      Text(
                        'إعطاء سلفة لشهر $advanceMonth 🤝',
                        style: const TextStyle(
                          fontSize: 17,
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
                        child: Text(emp.name),
                      );
                    }).toList(),
                    onChanged: widget.preselectedEmployee != null
                        ? null
                        : (emp) => setState(() => _selectedEmployee = emp),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'قيمة السلفة (ج.م) *',
                      prefixIcon: Icon(Icons.money_off, color: Colors.amber),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                      final num = double.tryParse(v.trim());
                      if (num == null || num <= 0) return 'مبلغ غير صالح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'تاريخ السلفة (الشهر المالي: $advanceMonth)',
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(dateFormat.format(_date)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'خصم تلقائي من المرتب:',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: _autoDeduct,
                          activeThumbColor: AppTheme.primary,
                          onChanged: (val) => setState(() => _autoDeduct = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات / سبب السلفة',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('صرف السلفة نقداً من الخزنة'),
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
