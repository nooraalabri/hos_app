import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../pages/hospital_admin_home.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../screens/settings_screen.dart';

class AdminDrawer extends StatelessWidget {
  final String? hospitalName;
  const AdminDrawer({super.key, this.hospitalName});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // الترجمات

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
                hospitalName ?? t.hospital,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(t.hospitalAdmin),
            ),
            const Divider(),

            _item(
              context,
              icon: Icons.home_outlined,
              text: t.home,
              route: AppRoutes.hospitalAdminHome,
            ),

            _item(
              context,
              icon: Icons.account_circle_outlined,
              text: t.myProfile,
              route: AppRoutes.hospitalProfile,
            ),

            _item(
              context,
              icon: Icons.group_outlined,
              text: t.myStaff,
              route: AppRoutes.myStaff,
            ),

            _item(
              context,
              icon: Icons.schedule_outlined,
              text: t.manageShifts,
              route: AppRoutes.manageShifts,
            ),

            _item(
              context,
              icon: Icons.bar_chart_outlined,
              text: t.reports,
              route: AppRoutes.hospitalReports,
            ),

            _item(
              context,
              icon: Icons.fact_check_outlined,
              text: t.acceptReject,
              route: AppRoutes.approveDoctors,
            ),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(t.settings),
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
                label: Text(
                  t.logout,
                  style: const TextStyle(color: Color(0xFF2D515C)),
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
