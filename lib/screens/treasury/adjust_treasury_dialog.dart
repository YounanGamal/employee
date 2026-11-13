import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class AdjustTreasuryDialog extends StatefulWidget {
  final bool isManualMovement;
  final bool isDeposit;
  final bool isSetOpeningBalance;

  const AdjustTreasuryDialog({
    super.key,
    this.isManualMovement = false,
    this.isDeposit = true,
    this.isSetOpeningBalance = false,
  });

  @override
  State<AdjustTreasuryDialog> createState() => _AdjustTreasuryDialogState();
}

class _AdjustTreasuryDialogState extends State<AdjustTreasuryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late DateTime _transactionDate;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _transactionDate = DateTime.now();

    if (widget.isSetOpeningBalance) {
      _amountController = TextEditingController(
        text: provider.initialBalance > 0
            ? provider.initialBalance.toStringAsFixed(0)
            : '',
      );
      _reasonController = TextEditingController(
        text: 'رصيد بداية الشهر المالي (${provider.selectedMonth})',
      );
    } else if (widget.isManualMovement) {
      _amountController = TextEditingController();
      _reasonController = TextEditingController();
    } else {
      _amountController = TextEditingController(
        text: provider.currentTreasuryBalance.toStringAsFixed(0),
      );
      _reasonController = TextEditingController();
    }
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

    if (widget.isSetOpeningBalance) {
      await provider.setPeriodOpeningBalance(provider.selectedMonth, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تعيين رصيد بداية شهر ${provider.selectedMonth} بمبلغ ${amount.toStringAsFixed(0)} ج.م',
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    if (widget.isManualMovement) {
      if (widget.isDeposit) {
        await provider.addTreasuryDeposit(
          amount: amount,
          date: _transactionDate,
          reason: reason.isNotEmpty ? reason : 'إيداع نقدي بالخزنة',
          month: provider.selectedMonth,
        );
      } else {
        await provider.addTreasuryWithdrawal(
          amount: amount,
          date: _transactionDate,
          reason: reason.isNotEmpty ? reason : 'سحب نقدي من الخزنة',
          month: provider.selectedMonth,
        );
      }
    } else {
      await provider.adjustTreasuryBalance(
        amount,
        reason,
        month: provider.selectedMonth,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حركة ورصيد الخزنة بنجاح'),
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

    String title = 'تسوية رصيد الخزنة 💰';
    if (widget.isSetOpeningBalance) {
      title = 'رصيد بداية الشهر (${provider.selectedMonth}) 🏦';
    } else if (widget.isManualMovement) {
      title = widget.isDeposit ? 'إيداع نقدية بالخزنة 📥' : 'سحب نقدية من الخزنة 📤';
    }

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
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  if (widget.isSetOpeningBalance) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Text(
                        '💡 ملاحظة: يبدأ كل شهر برصيد 0 ج.م تلقائياً ولا يتم ترحيل رصيد الشهر السابق. يمكنك كتابة المبلغ المتاح لبداية هذا الشهر هنا.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.isSetOpeningBalance
                          ? 'رصيد البداية المتاح للشهر (ج.م) *'
                          : (widget.isManualMovement
                              ? 'المبلغ (ج.م) *'
                              : 'الرصيد الفعلي الجديد (ج.م) *'),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال المبلغ';
                      }
                      final n = double.tryParse(v.trim());
                      if (n == null) return 'مبلغ غير صالح';
                      if (!widget.isSetOpeningBalance && n < 0) {
                        return 'المبلغ يجب أن يكون موجباً';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  if (widget.isManualMovement) ...[
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _transactionDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _transactionDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الحركة النقدية',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(dateFormat.format(_transactionDate)),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: widget.isSetOpeningBalance
                          ? 'ملاحظات'
                          : 'السبب / تفاصيل العملية *',
                      hintText: widget.isDeposit
                          ? 'مثلاً: توريد نقدية، دعم مالي، إيداع رأس مال...'
                          : 'مثلاً: جرد الخزنة، سحب طارئ...',
                      prefixIcon: const Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isManualMovement && !widget.isDeposit
                          ? AppTheme.expenseRed
                          : AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      widget.isSetOpeningBalance
                          ? 'حفظ رصيد بداية الشهر'
                          : (widget.isDeposit ? 'تأكيد الإيداع الفوري' : 'تأكيد السحب'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
