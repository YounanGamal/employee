import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class AdjustTreasuryDialog extends StatefulWidget {
  final bool isManualMovement;
  final bool isDeposit;

  const AdjustTreasuryDialog({
    super.key,
    this.isManualMovement = false,
    this.isDeposit = true,
  });

  @override
  State<AdjustTreasuryDialog> createState() => _AdjustTreasuryDialogState();
}

class _AdjustTreasuryDialogState extends State<AdjustTreasuryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _amountController = TextEditingController(
      text: widget.isManualMovement
          ? ''
          : provider.currentTreasuryBalance.toStringAsFixed(0),
    );
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reason = _reasonController.text.trim();
    final provider = context.read<AppProvider>();

    if (widget.isManualMovement) {
      await provider.manualTreasuryMovement(
        amount: amount,
        isCredit: widget.isDeposit,
        reason: reason.isNotEmpty
            ? reason
            : (widget.isDeposit ? 'إيداع نقدي' : 'سحب نقدي'),
      );
    } else {
      await provider.adjustTreasuryBalance(amount, reason);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حركة الخزنة بنجاح'),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'تسوية رصيد الخزنة 💰';
    if (widget.isManualMovement) {
      title = widget.isDeposit ? 'إيداع نقدي بالخزنة 📥' : 'سحب نقدي من الخزنة 📤';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                    Text(
                      title,
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
                const Divider(height: 20),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.isManualMovement
                        ? 'المبلغ (ج.م) *'
                        : 'الرصيد الفعلي الجديد (ج.م) *',
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                    final n = double.tryParse(v.trim());
                    if (n == null) return 'مبلغ غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'السبب / الملاحظة',
                    hintText: 'مثلاً: جرد الخزنة، رأس مال إضافي...',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isManualMovement && !widget.isDeposit
                        ? AppTheme.expenseRed
                        : AppTheme.primary,
                  ),
                  child: const Text('تأكيد وحفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
