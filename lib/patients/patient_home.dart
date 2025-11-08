import 'package:flutter/material.dart';
import 'patient_drawer.dart';
import 'ui.dart';
import 'profile_page.dart';

class PatientHome extends StatelessWidget {
  static const route = '/patient/home';
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Profile',
      drawer: const PatientDrawer(),
      body: const ProfilePageBody(),
    );
  }
}
