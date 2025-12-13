import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/settings_screen.dart';
import '../screens/chatbot_screen.dart';
import '../l10n/app_localizations.dart';
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
                AppLocalizations.of(context)!.patient,
                style: const TextStyle(
                  color: Color(0xFF5F7E86),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(),

            //  روابط الصفحات
            _item(context,
                icon: Icons.person_outline,
                text: AppLocalizations.of(context)!.my_profile,
              route: ProfilePageBody.route,),
            _item(context,
                icon: Icons.search, 
                text: AppLocalizations.of(context)!.search, 
                route: SearchPage.route),
            _item(context,
                icon: Icons.event,
                text: AppLocalizations.of(context)!.my_appointments,
                route: AppointmentPage.route),
            _item(context,
                icon: Icons.receipt_long,
                text: AppLocalizations.of(context)!.my_invoices,
                route: PatientInvoicesScreen.route,
                screen: const PatientInvoicesScreen()),
            _item(context,
                icon: Icons.payment,
                text: AppLocalizations.of(context)!.payment ?? 'Payments',
                route: PatientInvoicesScreen.route,
                screen: const PatientInvoicesScreen()), // Payments are shown in invoices
            _item(context,
                icon: Icons.qr_code,
                text: AppLocalizations.of(context)!.patient_qr_code,
                route: QRPage.route),
            _item(context,
                icon: Icons.description_outlined,
                text: AppLocalizations.of(context)!.medical_reports,
                route: MedicalReportsPage.route),
            _item(context,
                icon: Icons.medication_outlined,
                text: AppLocalizations.of(context)!.my_medicines,
                route: MedicinesPage.route),
            _item(context,
                icon: Icons.smart_toy,
                text: 'Chatbot',
                route: '',
                screen: const ChatbotScreen()),
            _item(context,
                icon: Icons.settings_outlined,
                text: AppLocalizations.of(context)!.settings,
                route: SettingsScreen.route),

            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                AppLocalizations.of(context)!.logout,
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
