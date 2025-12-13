// lib/patients/patient_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

import '../routes.dart';
import '../screens/settings_screen.dart';
import '../screens/chatbot_screen.dart';

import 'profile_page.dart';
import 'search_page.dart';
import 'appointment_page.dart';
import 'medical_reports_page.dart';
import 'medicines_page.dart';
import 'patient_invoices_screen.dart';
import 'qr_page.dart';

class PatientDrawer extends StatelessWidget {
  const PatientDrawer({super.key});

  Widget _item(
      BuildContext ctx, {
        required IconData icon,
        required String text,
        required String route,
        Widget? screen,
      }) {
    final cs = Theme.of(ctx).colorScheme;

    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
      onTap: () {
        Navigator.pop(ctx);
        if (screen != null) {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => screen),
          );
        } else if (ModalRoute.of(ctx)?.settings.name != route) {
          Navigator.pushReplacementNamed(ctx, route);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 10),

            // ================= PROFILE ICON =================
            CircleAvatar(
              radius: 36,
              backgroundColor: cs.primary,
              child: Icon(Icons.person, color: cs.onPrimary, size: 32),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                t.patient,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Divider(color: cs.outlineVariant),

            // ================= MENU ITEMS =================
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
              icon: Icons.receipt_long,
              text: t.my_invoices,
              route: AppRoutes.patientInvoices,
              screen: const PatientInvoicesScreen(),
            ),

            _item(
              context,
              icon: Icons.payment,
              text: t.payment ?? 'Payment',
              route: AppRoutes.patientInvoices,
              screen: const PatientInvoicesScreen(), // Payments are shown in invoices
            ),

            _item(
              context,
              icon: Icons.qr_code,
              text: t.patient_qr_code,
              route: AppRoutes.patientQR,
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
              icon: Icons.smart_toy,
              text: t.chatbot,
              route: '',
              screen: const ChatbotScreen(),
            ),

            _item(
              context,
              icon: Icons.settings_outlined,
              text: t.settings,
              route: SettingsScreen.route,
            ),

            Divider(color: cs.outlineVariant, height: 30),

            // ================= LOGOUT =================
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red.shade700),
              title: Text(
                t.logout,
                style: TextStyle(
                  color: Colors.red.shade700,
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
