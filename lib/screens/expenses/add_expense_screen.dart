import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../models/expense.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

enum DisbursementType {
  general,
  employee,
}

class AddExpenseScreen extends StatefulWidget {
  final Employee? preselectedEmployee;
  final String? initialCategory;

  const AddExpenseScreen({
    super.key,
    this.preselectedEmployee,
    this.initialCategory,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  DisbursementType _disbursementType = DisbursementType.general;
  Employee? _selectedEmployee;
  late String _selectedCategory;
  DateTime _date = DateTime.now();

  final List<String> _generalCategories = [
    'إيجار',
    'كهرباء ومرافق',
    'صيانة وتصليح',
    'بوفيه وضيافة',
    'أدوات ومستلزمات',
    'نثريات',
    'انتقالات ومواصلات',
    'تسويق وإعلانات',
    'أخرى',
  ];

  final List<String> _employeeCategories = [
    'مصاريف علاج ودواء 💊',
    'مكافأة تشجيعية ومنحة 🎁',
    'إعانة ومساعدة مالية 🤝',
    'بدل انتقالات ومهمات 🚗',
    'أدوات ومهمات عمل 🛠️',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedEmployee != null) {
      _disbursementType = DisbursementType.employee;
      _selectedEmployee = widget.preselectedEmployee;
      _selectedCategory = widget.initialCategory ?? _employeeCategories.first;
    } else {
      _selectedCategory = widget.initialCategory ?? _generalCategories.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(DisbursementType type, List<Employee> employees) {
    setState(() {
      _disbursementType = type;
      if (type == DisbursementType.employee) {
        if (_selectedEmployee == null && employees.isNotEmpty) {
          _selectedEmployee = employees.first;
        }
        if (!_employeeCategories.contains(_selectedCategory)) {
          _selectedCategory = _employeeCategories.first;
        }
      } else {
        if (!_generalCategories.contains(_selectedCategory)) {
          _selectedCategory = _generalCategories.first;
        }
      }
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_disbursementType == DisbursementType.employee && _selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار العامل المراد الصرف له'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    final provider = context.read<AppProvider>();
    final isEmp = _disbursementType == DisbursementType.employee;

    final expense = Expense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      category: _selectedCategory,
      description: description,
      date: _date,
      notes: notes,
      employeeId: isEmp ? _selectedEmployee?.id : null,
      employeeName: isEmp ? _selectedEmployee?.name : null,
    );

    await provider.addExpense(expense);

    if (mounted) {
      final msg = isEmp
          ? 'تم صرف ${amount.toStringAsFixed(0)} ج لحساب العامل (${_selectedEmployee?.name}) بنجاح (بدون خصم من المرتب)'
          : 'تم تسجيل المنصرف بقيمة ${amount.toStringAsFixed(0)} ج وخصمه من الخزنة';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isEmp ? Colors.teal.shade700 : AppTheme.expenseRed,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final employees = provider.employees.where((e) => e.isActive).toList();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final currentBalance = provider.currentTreasuryBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل صرف / منصرف 📤'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // رصيد الخزنة الحالي
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.amber.shade900),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'رصيد الخزنة المتاح حالياً: ${currentBalance.toStringAsFixed(0)} ج.م',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // اختيار نوع الصرف (عام أو لعامل)
                const Text(
                  'نوع الصرف:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<DisbursementType>(
                  segments: const [
                    ButtonSegment<DisbursementType>(
                      value: DisbursementType.general,
                      icon: Icon(Icons.business_outlined),
                      label: Text('منصرف عام للمنشأة'),
                    ),
                    ButtonSegment<DisbursementType>(
                      value: DisbursementType.employee,
                      icon: Icon(Icons.person_outline),
                      label: Text('صرف لعامل (علاج / مكافأة)'),
                    ),
                  ],
                  selected: {_disbursementType},
                  onSelectionChanged: (Set<DisbursementType> newSelection) {
                    _onTypeChanged(newSelection.first, employees);
                  },
                  style: ButtonStyle(
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // إذا كان الصرف لعامل
                if (_disbursementType == DisbursementType.employee) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.teal.shade800, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'صرف مالي للعامل (غير مخصوم وغير مسترد)',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'هذا المبلغ سيتم صرفه من الخزنة لصالح العامل مثل (علاج، مكافأة، إعانة، بدل) ولن يتم خصمه من مرتبه الشهري ولا يُسجل كسلفة عليه.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.teal.shade900,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // اختيار العامل
                  DropdownButtonFormField<String>(
                    initialValue: _selectedEmployee?.id ?? (employees.isNotEmpty ? employees.first.id : null),
                    decoration: const InputDecoration(
                      labelText: 'اختر العامل *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: employees.map((emp) {
                      return DropdownMenuItem<String>(
                        value: emp.id,
                        child: Text('${emp.name} (${emp.phone})'),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        setState(() {
                          _selectedEmployee = employees.firstWhere((e) => e.id == id);
                        });
                      }
                    },
                    validator: (v) {
                      if (_disbursementType == DisbursementType.employee && (v == null || v.isEmpty)) {
                        return 'يرجى اختيار العامل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                ],

                // تصنيف الصرف
                DropdownButtonFormField<String>(
                  key: ValueKey('$_disbursementType-$_selectedCategory'),
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'تصنيف المنصرف *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: (_disbursementType == DisbursementType.employee
                          ? _employeeCategories
                          : _generalCategories)
                      .map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    if (cat != null) {
                      setState(() => _selectedCategory = cat);
                    }
                  },
                ),
                const SizedBox(height: 18),

                // المبلغ
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المنصرف (ج.م) *',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money, color: AppTheme.expenseRed),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0) return 'يرجى إدخال مبلغ صحيح أكبر من صفر';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // البيان / التفاصيل
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'البيان (تفاصيل الصرف) *',
                    hintText: _disbursementType == DisbursementType.employee
                        ? 'مثال: مصاريف علاج كشف طبي وأدوية، مكافأة تميز...'
                        : 'مثال: فاتورة كهرباء شهر سبتمبر، شراء أدوات...',
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'يرجى إدخال بيان المنصرف' : null,
                ),
                const SizedBox(height: 18),

                // تاريخ الصرف
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الصرف',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(dateFormat.format(_date)),
                  ),
                ),
                const SizedBox(height: 18),

                // ملاحظات إضافية
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية (اختياري)',
                    hintText: 'أي تفاصيل أخرى أو رقم إيصال...',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 32),

                // زر التأكيد
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _disbursementType == DisbursementType.employee
                          ? Colors.teal.shade700
                          : AppTheme.expenseRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _disbursementType == DisbursementType.employee
                          ? 'تأكيد صرف المبلغ للعامل من الخزنة'
                          : 'تأكيد تسجيل المنصرف وخصمه من الخزنة',
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

