import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../providers/app_provider.dart';

class EmployeeDialog extends StatefulWidget {
  final Employee? employee;

  const EmployeeDialog({super.key, this.employee});

  @override
  State<EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<EmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;
  late TextEditingController _notesController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _phoneController = TextEditingController(text: widget.employee?.phone ?? '');
    _salaryController = TextEditingController(
      text: widget.employee != null ? widget.employee!.salary.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: widget.employee?.notes ?? '');
    _isActive = widget.employee?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final salary = double.tryParse(_salaryController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim();

    final provider = context.read<AppProvider>();

    if (widget.employee == null) {
      final newEmp = Employee(
        id: 'emp_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: phone,
        salary: salary,
        notes: notes,
        isActive: _isActive,
      );
      provider.addEmployee(newEmp);
    } else {
      final updated = widget.employee!.copyWith(
        name: name,
        phone: phone,
        salary: salary,
        notes: notes,
        isActive: _isActive,
      );
      provider.updateEmployee(updated);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.employee == null ? 'تمت إضافة العامل بنجاح' : 'تم تحديث بيانات العامل بنجاح',
        ),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;

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
                        isEdit ? 'تعديل بيانات العامل' : 'إضافة عامل جديد',
                        style: const TextStyle(
                          fontSize: 18,
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
                  const Divider(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم العامل *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'يرجى إدخال اسم العامل' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الموبايل *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'يرجى إدخال رقم الموبايل' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _salaryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المرتب الأساسي (ج.م) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال المرتب';
                      if (double.tryParse(v.trim()) == null) return 'رقم غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      prefixIcon: Icon(Icons.note_alt_outlined),
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
                          'حالة العامل (نشط في العمل):',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                        ),
                        Switch(
                          value: _isActive,
                          activeThumbColor: Colors.teal.shade700,
                          onChanged: (val) {
                            setState(() {
                              _isActive = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة العامل'),
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
