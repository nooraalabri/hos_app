import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../widgets/app_button.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_turned_in_outlined, size: 140, color: Color(0xFF9AAAB2)),
                    const SizedBox(height: 24),
                    Text(
                      loc?.welcome ?? 'Hospital appointment',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      text: loc?.login ?? 'login',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: loc?.signup ?? 'sign up',
                      filled: false,
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.selectRole),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.shade300,
          ),
          _LanguageButton(
            code: 'ar',
            label: 'العربية',
            isSelected: currentLang == 'ar',
            onTap: () => appProvider.changeLanguage('ar'),
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

  const _LanguageButton({
    required this.code,
    required this.label,
    required this.isSelected,
    required this.onTap,
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
            color: isSelected ? const Color(0xFF2D515C) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
