import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../screens/settings_screen.dart'; // 👈 ضروري تضيفي هذا

class AdminDrawer extends StatelessWidget {
  final String? hospitalName;
  const AdminDrawer({super.key, this.hospitalName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.local_hospital)),
              title: Text(hospitalName ?? 'Hospital'),
              subtitle: const Text('Hospital Admin'),
            ),
            const Divider(),
            _item(context,
                icon: Icons.person_outline,
                text: 'My profile',
                route: AppRoutes.hospitalProfile),
            _item(context,
                icon: Icons.badge_outlined,
                text: 'My staff',
                route: AppRoutes.myStaff),
            _item(context,
                icon: Icons.pie_chart_outline,
                text: 'Reports',
                route: AppRoutes.hospitalReports),
            _item(context,
                icon: Icons.fact_check_outlined,
                text: 'Accept / Reject',
                route: AppRoutes.approveDoctors),

            // ✅ هنا التعديل
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()), // 👈 يفتح صفحة Settings
                );
              },
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => AuthService.logoutAndGoWelcome(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext ctx,
      {required IconData icon,
        required String text,
        String? route,
        VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(ctx);
        if (route != null) Navigator.pushNamed(ctx, route);
        if (onTap != null) onTap();
      },
    );
  }
}
