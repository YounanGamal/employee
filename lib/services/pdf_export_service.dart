import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/employee.dart';
import '../models/advance.dart';
import '../models/salary_record.dart';
import '../models/expense.dart';
import '../models/treasury_transaction.dart';

class PdfExportService {
  static Future<pw.ThemeData> _getPdfTheme() async {
    try {
      final font = await PdfGoogleFonts.cairoRegular();
      final boldFont = await PdfGoogleFonts.cairoBold();
      return pw.ThemeData.withFont(base: font, bold: boldFont);
    } catch (_) {
      return pw.ThemeData.base();
    }
  }

  static Future<void> printSalariesReport({
    required List<SalaryRecord> salaries,
    required String month,
    required BuildContext context,
  }) async {
    final doc = pw.Document();
    final theme = await _getPdfTheme();

    final totalNet = salaries.fold<double>(0, (sum, s) => sum + s.netSalary);
    final paidCount = salaries.where((s) => s.isPaid).length;

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('تقرير مرتبات شهر $month',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text('تاريخ الطباعة: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('عدد العاملين: ${salaries.length}'),
                  pw.Text('المدفوع: $paidCount'),
                  pw.Text('المتبقي: ${salaries.length - paidCount}'),
                  pw.Text('إجمالي الصافي: ${totalNet.toStringAsFixed(2)} ج.م',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.TableHelper.fromTextArray(
              headers: [
                'م',
                'اسم العامل',
                'الأساسي',
                'إضافات',
                'خصومات',
                'سلف',
                'الصافي',
                'الحالة',
              ],
              data: List.generate(salaries.length, (i) {
                final s = salaries[i];
                return [
                  '${i + 1}',
                  s.employeeName,
                  s.basicSalary.toStringAsFixed(1),
                  s.additions.toStringAsFixed(1),
                  s.deductions.toStringAsFixed(1),
                  s.advancesDeducted.toStringAsFixed(1),
                  s.netSalary.toStringAsFixed(1),
                  s.isPaid ? 'مدفوع' : 'مستحق',
                ];
              }),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.teal700),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Salaries_Report_$month.pdf',
    );
  }

  static Future<void> printTreasuryReport({
    required List<TreasuryTransaction> txs,
    required double currentBalance,
    required BuildContext context,
  }) async {
    final doc = pw.Document();
    final theme = await _getPdfTheme();

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('تقرير حركة الخزنة 💰',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'الرصيد الحالي: ${currentBalance.toStringAsFixed(2)} ج.م',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'م',
                'التاريخ',
                'النوع',
                'المبلغ',
                'البيان',
              ],
              data: List.generate(txs.length, (i) {
                final t = txs[i];
                final sign = t.isCredit ? '+' : '-';
                return [
                  '${i + 1}',
                  DateFormat('yyyy/MM/dd').format(t.date),
                  t.typeLabel,
                  '$sign${t.amount.toStringAsFixed(2)} ج',
                  t.title,
                ];
              }),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.indigo700),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Treasury_Report.pdf',
    );
  }

  static Future<void> printEmployeeStatement({
    required Employee emp,
    required List<SalaryRecord> salaries,
    required List<Advance> advances,
    List<Expense> disbursements = const [],
    required double totalPaid,
    required double remainingAdvances,
    required BuildContext context,
  }) async {
    final doc = pw.Document();
    final theme = await _getPdfTheme();

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('كشف حساب العامل: ${emp.name}',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('الهاتف: ${emp.phone}',
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('المرتب الأساسي: ${emp.salary.toStringAsFixed(0)} ج'),
                  pw.Text('إجمالي المدفوع: ${totalPaid.toStringAsFixed(0)} ج'),
                  pw.Text('متبقي سلف: ${remainingAdvances.toStringAsFixed(0)} ج'),
                  pw.Text(
                      'الحالة: ${emp.isActive ? "نشط" : "غير نشط"}',
                      style: pw.TextStyle(
                          color: emp.isActive
                              ? PdfColors.green800
                              : PdfColors.red800)),
                ],
              ),
            ),
            pw.Text('سجل المرتبات',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['الشهر', 'الأساسي', 'إضافات', 'خصم', 'سلف', 'الصافي', 'الحالة'],
              data: salaries.map((s) {
                return [
                  s.month,
                  s.basicSalary.toStringAsFixed(0),
                  s.additions.toStringAsFixed(0),
                  s.deductions.toStringAsFixed(0),
                  s.advancesDeducted.toStringAsFixed(0),
                  s.netSalary.toStringAsFixed(0),
                  s.isPaid ? 'مدفوع' : 'مستحق',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.teal800),
              cellAlignment: pw.Alignment.center,
            ),
            pw.SizedBox(height: 16),
            pw.Text('سجل السلف',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (advances.isEmpty)
              pw.Text('لا توجد سلف مسجلة لهذا العامل')
            else
              pw.TableHelper.fromTextArray(
                headers: ['التاريخ', 'القيمة', 'المسدد', 'المتبقي', 'الحالة'],
                data: advances.map((a) {
                  return [
                    DateFormat('yyyy/MM/dd').format(a.date),
                    a.amount.toStringAsFixed(0),
                    a.paidAmount.toStringAsFixed(0),
                    a.remainingAmount.toStringAsFixed(0),
                    a.isFullyPaid ? 'مسددة' : 'متبقية',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignment: pw.Alignment.center,
              ),
            if (disbursements.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('سجل المصروفات المباشرة (علاج / إكراميات لا تخصم)',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['التاريخ', 'البند', 'المبلغ', 'البيان', 'ملاحظات'],
                data: disbursements.map((d) {
                  return [
                    DateFormat('yyyy/MM/dd').format(d.date),
                    d.category,
                    d.amount.toStringAsFixed(0),
                    d.description,
                    d.notes,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.teal700),
                cellAlignment: pw.Alignment.center,
              ),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Statement_${emp.name}.pdf',
    );
  }
}
