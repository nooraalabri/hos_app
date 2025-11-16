import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../routes.dart';
import '../screens/settings_screen.dart';
import '../l10n/app_localizations.dart';

class HeadAdminHome extends StatelessWidget {
  const HeadAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.headAdmin),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // ✅ Review Hospitals
            _HomeTile(
              title: t.reviewHospitals,
              subtitle: t.reviewHospitalsSubtitle,
              icon: Icons.fact_check_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.approveHospitals,
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Reports
            _HomeTile(
              title: t.reports,
              subtitle: t.reportsSubtitle,
              icon: Icons.bar_chart_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.headAdminHospitalDetails,
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Dashboard
            _HomeTile(
              title: t.dashboard,
              subtitle: t.dashboardSubtitle,
              icon: Icons.dashboard_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.headAdminReports,
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () => AuthService.logoutAndGoWelcome(context),
              child: Text(t.logout),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D515C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
