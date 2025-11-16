import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';
import '../routes.dart';
import '../widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 140,
                  color: Color(0xFF9AAAB2),
                ),

                const SizedBox(height: 24),

                // العنوان متعدد اللغات
                Text(
                  t.welcomeTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // زر تسجيل الدخول
                AppButton(
                  text: t.login,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                ),

                const SizedBox(height: 16),

                // زر إنشاء حساب
                AppButton(
                  text: t.signUp,
                  filled: false,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.selectRole),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
