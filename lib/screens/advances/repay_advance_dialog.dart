import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/advance.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class RepayAdvanceDialog extends StatefulWidget {
  final Advance advance;

  const RepayAdvanceDialog({super.key, required this.advance});

  @override
  State<RepayAdvanceDialog> createState() => _RepayAdvanceDialogState();
}

class _RepayAdvanceDialogState extends State<RepayAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.advance.remainingAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || amount > widget.advance.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'المبلغ يجب أن يكون بين 1 و ${widget.advance.remainingAmount.toStringAsFixed(0)} ج',
          ),
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    await provider.repayAdvanceDirectly(widget.advance.id, amount);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل سداد سلفة بقيمة ${amount.toStringAsFixed(0)} ج وإيداعها بالخزنة 💰',
          ),
          backgroundColor: AppTheme.incomeGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'سداد سلفة نقداً 💵',
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
                Text(
                  'العامل: ${widget.advance.employeeName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'المتبقي الحالي من السلفة: ${widget.advance.remainingAmount.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المسدد نقداً (ج.م) *',
                    prefixIcon: Icon(Icons.payments_outlined, color: Colors.green),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'مبلغ غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.incomeGreen),
                  child: const Text('تأكيد السداد وتوريد المبلغ للخزنة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
