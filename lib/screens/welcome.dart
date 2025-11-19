import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../routes.dart';
import '../widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 140,
                  color: cs.primary.withValues(alpha: 0.7), // يشتغل على الدارك واللايت
                ),

                const SizedBox(height: 24),

                // العنوان
                Text(
                  t.welcomeTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: cs.onSurface,
                  ),
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
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.selectRole,
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
