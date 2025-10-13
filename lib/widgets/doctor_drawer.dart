import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../screens/doctor/my_shifts.dart';
import '../screens/doctor/weekly_shifts.dart';
import '../screens/doctor/reviews.dart';

class DoctorDrawer extends StatelessWidget {
  final String doctorId;
  final String doctorName;
  const DoctorDrawer({super.key, required this.doctorId, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF285C63), // نفس الأزرق في التصميم
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

          // ✅ My profile
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("My profile"),
            onTap: () {
              // TODO: افتحي صفحة بروفايل الدكتور
            },
          ),

          // ✅ My shifts (اليوم فقط)
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text("My shifts"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyShiftsScreen(doctorId: doctorId),
                ),
              );
            },
          ),

          // ✅ Weekly Shifts
          ListTile(
            leading: const Icon(Icons.view_week),
            title: const Text("Weekly Shifts"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeeklyShiftsScreen(doctorId: doctorId),
                ),
              );
            },
          ),

          // ✅ Chatbot
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text("Chatbot"),
            onTap: () {
              // TODO: افتحي شاشة الشات بوت
            },
          ),

          // ✅ Reviews
          ListTile(
            leading: const Icon(Icons.reviews),
            title: const Text("Reviews"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsScreen(doctorId: doctorId),
                ),
              );
            },
          ),

          // ✅ Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
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

          // ✅ Logout
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
              label: const Text("Logout", style: TextStyle(color: Colors.white)),
              onPressed: () {
                // TODO: logout logic
              },
            ),
          ),
        ],
      ),
    );
  }
}
