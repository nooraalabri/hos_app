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

    return AppScaffold(
      title: t.myProfile,
      drawer: const PatientDrawer(),
      body: const ProfilePageBody(),
    );
  }
}
