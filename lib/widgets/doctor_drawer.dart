import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../screens/settings_screen.dart';
import '../screens/doctor/my_shifts_screen.dart';
import '../screens/doctor/weekly_shifts_screen.dart';
import '../screens/doctor/reviews.dart';

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
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF285C63),
            ),
            accountName: Text(
              doctorName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: null,
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF285C63)),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: Text(t.myProfile),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(t.myShifts),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyShiftsScreen(doctorId: doctorId),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.view_week),
            title: Text(t.weeklyShifts),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShiftsOverviewScreen(doctorId: doctorId),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: Text(t.chatbot),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.reviews),
            title: Text(t.reviews),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsScreen(doctorId: doctorId),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(t.settings),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF285C63),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(t.logout, style: const TextStyle(color: Colors.white)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
