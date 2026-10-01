import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/income.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class AddIncomeDialog extends StatefulWidget {
  const AddIncomeDialog({super.key});

  @override
  State<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reason = _reasonController.text.trim();
    final notes = _notesController.text.trim();

    final income = Income(
      id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      reason: reason,
      date: _date,
      notes: notes,
    );

    final provider = context.read<AppProvider>();
    await provider.addIncome(income);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل وارد بقيمة ${amount.toStringAsFixed(0)} ج وإضافته للخزنة 💰',
          ),
          backgroundColor: AppTheme.incomeGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

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
                      const Text(
                        'تسجيل وارد جديد 📥',
                        style: TextStyle(
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
                  const Divider(height: 20),

                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (ج.م) *',
                      prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                      final num = double.tryParse(v.trim());
                      if (num == null || num <= 0) return 'مبلغ غير صالح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'السبب / المصدر *',
                      hintText: 'مثلاً: مبيعات كاش، تحصيل من عميل...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'يرجى إدخال السبب' : null,
                  ),
                  const SizedBox(height: 14),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(dateFormat.format(_date)),
                    ),
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
                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.incomeGreen,
                    ),
                    child: const Text('تسجيل الوارد وإيداعه بالخزنة'),
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
