import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hos_app/screens/login_screen.dart';

void main() {
  group('LoginScreen UI Tests', () {
    testWidgets('renders all main widgets correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      //  تأكدي من العناصر الأساسية
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('New user? '), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // اضغطي زر Login بدون إدخال بيانات
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      //  تأكدي من رسائل الخطأ
      expect(find.text('Enter valid email'), findsOneWidget);
      expect(find.text('Min 8 chars'), findsOneWidget);
    });

    testWidgets('shows error if email is invalid', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
      await tester.enterText(find.byType(TextFormField).last, '12345678');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Enter valid email'), findsOneWidget);
    });

    testWidgets('does not show validation errors if inputs are valid', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'Password1!');
      await tester.tap(find.text('Login'));
      await tester.pump();

      //  ما تظهر رسائل خطأ في الفاليديشن
      expect(find.text('Enter valid email'), findsNothing);
      expect(find.text('Min 8 chars'), findsNothing);
    });
  });
}
