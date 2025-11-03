import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hos_app/screens/register_patient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RegisterPatientScreen loads and shows required fields', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    await tester.pumpWidget(const MaterialApp(home: RegisterPatientScreen()));

    expect(find.text('Register'), findsOneWidget);
    expect(find.text('My Name'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('Civil Number'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Shows validation errors when empty', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    await tester.pumpWidget(const MaterialApp(home: RegisterPatientScreen()));

    // اضغطي على الزر بدون تعبئة
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // نتحقق من وجود أي رسائل خطأ
    expect(find.textContaining('required', findRichText: true), findsWidgets);
  });

  testWidgets('Accepts valid input', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    await tester.pumpWidget(const MaterialApp(home: RegisterPatientScreen()));

    // إدخال بيانات صحيحة
    await tester.enterText(find.byType(TextFormField).at(0), 'Noora Al Abri');
    await tester.enterText(find.byType(TextFormField).at(1), '2000-01-01');
    await tester.enterText(find.byType(TextFormField).at(2), '12345678');
    await tester.enterText(find.byType(TextFormField).at(3), 'noora@example.com');
    await tester.enterText(find.byType(TextFormField).at(4), 'Strong@123');
    await tester.enterText(find.byType(TextFormField).at(5), 'Strong@123');

    // اضغطي على الزر
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // تأكدي إنه ما فيه أي رسالة خطأ فيها required أو invalid
    expect(find.textContaining('required', findRichText: true), findsNothing);
    expect(find.textContaining('invalid', findRichText: true), findsNothing);
    expect(find.textContaining('match', findRichText: true), findsNothing);
  });
}
