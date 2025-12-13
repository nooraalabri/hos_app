import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../routes.dart';
import '../widgets/app_button.dart';
import '../providers/app_provider.dart';

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
        body: Stack(
          children: [
            Center(
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
            // Language Switcher in top right
            Positioned(
              top: 16,
              right: 16,
              child: _LanguageSwitcher(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentLang = appProvider.language;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageButton(
            code: 'en',
            label: 'English',
            isSelected: currentLang == 'en',
            onTap: () => appProvider.changeLanguage('en'),
            cs: cs,
          ),
          Container(
            width: 1,
            height: 30,
            color: cs.outlineVariant,
          ),
          _LanguageButton(
            code: 'ar',
            label: 'العربية',
            isSelected: currentLang == 'ar',
            onTap: () => appProvider.changeLanguage('ar'),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String code;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _LanguageButton({
    required this.code,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
