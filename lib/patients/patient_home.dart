import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import 'patient_drawer.dart';
import 'ui.dart';
import 'profile_page.dart';

class PatientHome extends StatelessWidget {
  static const route = '/patient/home';
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      title: t.myProfile,
      drawer: const PatientDrawer(),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: const ProfilePageBody(),
      ),
    );
  }
}
