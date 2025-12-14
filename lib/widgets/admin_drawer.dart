import 'package:flutter/material.dart';
import '../pages/hospital_admin_home.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../screens/settings_screen.dart';
import '../screens/chatbot_screen.dart';

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
              leading: const CircleAvatar(
                child: Icon(Icons.local_hospital, color: Colors.white),
                backgroundColor: Color(0xFF2D515C),
              ),
              title: Text(
                hospitalName ?? 'Hospital',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Hospital Admin'),
            ),
            const Divider(),

            _item(
              context,
              icon: Icons.home_outlined,
              text: 'Home',
              route: AppRoutes.hospitalAdminHome,
            ),

            _item(
              context,
              icon: Icons.account_circle_outlined,
              text: 'My Profile',
              route: AppRoutes.hospitalProfile,
            ),

            _item(
              context,
              icon: Icons.group_outlined,
              text: 'My Staff',
              route: AppRoutes.myStaff,
            ),

            _item(
              context,
              icon: Icons.schedule_outlined,
              text: 'Manage Shifts',
              route: AppRoutes.manageShifts,
            ),

            _item(
              context,
              icon: Icons.bar_chart_outlined,
              text: 'Reports',
              route: AppRoutes.hospitalReports,
            ),

            _item(
              context,
              icon: Icons.fact_check_outlined,
              text: 'Accept / Reject',
              route: AppRoutes.approveDoctors,
            ),

            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('Chatbot'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => AuthService.logoutAndGoWelcome(context),
                icon: const Icon(Icons.logout, color: Color(0xFF2D515C)),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Color(0xFF2D515C)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6EBEC),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
      BuildContext ctx, {
        required IconData icon,
        required String text,
        String? route,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2D515C)),
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
