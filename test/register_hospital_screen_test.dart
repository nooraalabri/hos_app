import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hos_app/screens/register_hospital.dart';

void main() {
  testWidgets('RegisterHospitalScreen loads and validates inputs', (WidgetTester tester) async {

    await tester.pumpWidget(const MaterialApp(
      home: RegisterHospitalScreen(),
    ));

    // ⃣ تأكدي أن النصوص الأساسية ظاهرة
    expect(find.text('Register Hospital'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Hospital Name'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);

    //  جرّبي تضغطي زر Sign up بدون إدخال بيانات
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    //  تأكدي أن رسائل الخطأ ظهرت
    expect(find.text('Required'), findsWidgets);
    expect(find.text('Valid email required'), findsOneWidget);
  });

  testWidgets('RegisterHospitalScreen accepts valid input', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: RegisterHospitalScreen(),
    ));

    // إدخال بيانات صحيحة
    await tester.enterText(find.byType(TextFormField).at(0), 'Royal Hospital');
    await tester.enterText(find.byType(TextFormField).at(1), 'royal@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Strong@123');
    await tester.enterText(find.byType(TextFormField).at(3), 'Strong@123');
    await tester.enterText(find.byType(TextFormField).at(4), 'Muscat');

    await tester.tap(find.text('Sign up'));
    await tester.pump();

    //  التحقق أن ما في أخطاء ظاهرة
    expect(find.text('Required'), findsNothing);
    expect(find.text('Valid email required'), findsNothing);
    expect(find.text('Passwords do not match'), findsNothing);
  });
}
