import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../screens/settings_screen.dart';
import '../screens/chatbot_screen.dart';
import '../screens/doctor/my_shifts_screen.dart';
import '../screens/doctor/weekly_shifts_screen.dart';
import '../screens/doctor/reviews.dart';
import '../screens/doctor/doctor_appointments_screen.dart';
import '../screens/doctor/doctor_invoices_screen.dart';
import '../screens/doctor/edit_profile.dart';
import '../routes.dart';
import '../services/auth_service.dart';

class DoctorDrawer extends StatelessWidget {
  final String doctorId;
  final String doctorName;

  const DoctorDrawer({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // الترجمات

    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2D515C)),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text('Doctor Menu',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(t.home),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(t.myShifts),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyShiftsScreen(doctorId: doctorId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(t.weeklyShifts),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShiftsOverviewScreen(doctorId: doctorId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(t.my_appointments),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorAppointmentsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.reviews),
            title: Text(t.reviews),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsScreen(doctorId: doctorId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(t.my_invoices),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorInvoicesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: Text(t.chatbot),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(t.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              t.logout,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => AuthService.logoutAndGoWelcome(context),
          ),
        ],
      ),
    );
  }
}
