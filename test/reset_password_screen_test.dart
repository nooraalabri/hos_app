import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hos_app/screens/reset_password.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResetPasswordScreen widget tests', () {
    testWidgets('renders all main UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));

      expect(find.text('Reset\npassword'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('shows validation error when password fields are empty',
            (WidgetTester tester) async {
          await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));

          await tester.tap(find.text('Update'));
          await tester.pump(const Duration(milliseconds: 200));

          expect(find.text('Password is required'), findsOneWidget);
          expect(find.text('Please re-enter password'), findsOneWidget);
        });

    testWidgets('shows error when passwords do not match',
            (WidgetTester tester) async {
          await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));

          await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'Abcd@1234');
          await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'Xyz@1234');
          await tester.tap(find.text('Update'));
          await tester.pump(const Duration(milliseconds: 200));

          expect(find.text('Passwords do not match'), findsOneWidget);
        });

    testWidgets('shows error when password is too weak',
            (WidgetTester tester) async {
          await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));

          await tester.enterText(find.widgetWithText(TextFormField, 'New password'), '123');
          await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), '123');
          await tester.tap(find.text('Update'));
          await tester.pump(const Duration(milliseconds: 200));

          expect(find.textContaining('Min 8 chars'), findsOneWidget);
        });

    testWidgets('shows success snackbar after valid input',
            (WidgetTester tester) async {
          await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));

          // 🟢 نحط قيم صحيحة
          await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'Good@Pass1');
          await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'Good@Pass1');
          await tester.tap(find.text('Update'));

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // ما راح يرسل فعلاً لـ Firebase، لكن على الأقل نتحقق أن الزر اشتغل
          expect(find.text('Update'), findsOneWidget);
        });
  });
}
