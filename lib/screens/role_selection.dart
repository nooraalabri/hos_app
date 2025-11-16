import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../routes.dart';
import '../widgets/app_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                size: 120,
                color: Color(0xFF9AAAB2),
              ),
              const SizedBox(height: 16),

              Text(
                t.selectRole,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              AppButton(
                text: t.roleHospital,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.regHospital),
              ),
              const SizedBox(height: 12),

              AppButton(
                text: t.roleDoctor,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.regDoctor),
              ),
              const SizedBox(height: 12),

              AppButton(
                text: t.rolePatient,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.regPatient),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
