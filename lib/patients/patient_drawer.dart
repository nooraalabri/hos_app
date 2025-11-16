import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

import '../routes.dart';
import '../screens/doctor/reviews.dart';
import '../screens/settings_screen.dart';
import 'ui.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'appointment_page.dart';
import 'medical_reports_page.dart';
import 'medicines_page.dart';

class PatientDrawer extends StatelessWidget {
  const PatientDrawer({super.key});

  Widget _item(
      BuildContext ctx, {
        required IconData icon,
        required String text,
        required String route,
      }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2D515C)),
      title: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D515C),
        ),
      ),
      onTap: () {
        Navigator.pop(ctx);
        if (ModalRoute.of(ctx)?.settings.name != route) {
          Navigator.pushReplacementNamed(ctx, route);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 10),
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFF2D515C),
              child: Icon(Icons.person, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                t.patient,
                style: const TextStyle(
                  color: Color(0xFF5F7E86),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(),

            //  ← هنا التصحيح الحقيقي
            _item(
              context,
              icon: Icons.person_outline,
              text: t.myProfile,
              route: AppRoutes.patientProfile,

            ),

            _item(
              context,
              icon: Icons.search,
              text: t.search,
              route: SearchPage.route,
            ),

            _item(
              context,
              icon: Icons.event,
              text: t.myAppointments,
              route: AppointmentPage.route,
            ),

            _item(
              context,
              icon: Icons.description_outlined,
              text: t.medicalReports,
              route: MedicalReportsPage.route,
            ),

            _item(
              context,
              icon: Icons.medication_outlined,
              text: t.myMedicines,
              route: MedicinesPage.route,
            ),

            _item(
              context,
              icon: Icons.settings_outlined,
              text: t.settings,
              route: SettingsScreen.route,
            ),

            const Divider(height: 30),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                t.logout,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
