import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../routes.dart';
import '../widgets/app_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 120,
                color: cs.onSurface.withValues(alpha:0.5),
              ),
              const SizedBox(height: 16),

              Text(
                t.selectRole,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: t.roleHospital,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.regHospital),
              ),
              const SizedBox(height: 12),

              AppButton(
                text: t.roleDoctor,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.regDoctor),
              ),
              const SizedBox(height: 12),

              AppButton(
                text: t.rolePatient,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.regPatient),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
