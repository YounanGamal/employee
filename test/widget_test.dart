import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:employee/main.dart';

void main() {
  testWidgets('App launches and renders Dashboard successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify main components rendered
    expect(find.text('نظام إدارة العاملين والخزنة'), findsWidgets);
    expect(find.text('💰 رصيد الخزنة الحالي'), findsOneWidget);
    expect(find.text('رصيد الخزنة'), findsWidgets);
    expect(find.text('إجمالي الوارد'), findsWidgets);
    expect(find.text('إجمالي المنصرف'), findsWidgets);
  });
}
