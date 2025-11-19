import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../routes.dart';
import '../widgets/admin_drawer.dart';
import '../l10n/app_localizations.dart';

class HospitalAdminHome extends StatelessWidget {
  const HospitalAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>?>(
      future: FS.hospitalForAdmin(uid),
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final data = snap.data;
        final name = (data?['name'] ?? t.hospitalAdmin) as String;
        final status = (data?['status'] ?? t.pending) as String;

        return Scaffold(
          drawer: AdminDrawer(hospitalName: name),
          appBar: AppBar(
            title: Text(name),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: t.logout,
                onPressed: () => AuthService.logoutAndGoWelcome(context),
                icon: Icon(Icons.logout, color: cs.onPrimary),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addDoctorByAdmin),
            icon: Icon(Icons.person_add_alt_1, color: cs.onPrimary),
            label: Text(
              t.addDoctor,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),

          body: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _HospitalCard(
                name: name,
                status: status,
                email: data?['email'],
              ),
              const SizedBox(height: 16),

              _HomeTile(
                title: t.myProfile,
                subtitle: t.hospitalProfileSubtitle,
                icon: Icons.person_outline,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.hospitalProfile),
              ),
              const SizedBox(height: 12),

              _HomeTile(
                title: t.myStaff,
                subtitle: t.myStaffSubtitle,
                icon: Icons.badge_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.myStaff),
              ),
              const SizedBox(height: 12),

              _HomeTile(
                title: t.reports,
                subtitle: t.reportsOverview,
                icon: Icons.pie_chart_outline,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.hospitalReports),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final String name;
  final String? email;
  final String status;
  const _HospitalCard({
    required this.name,
    this.email,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: isDark ? cs.primary : const Color(0xFF2D515C),
            child: Icon(Icons.local_hospital, color: cs.onPrimary),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: cs.primary,
            ),
          ),
          subtitle: email == null
              ? null
              : Text(
            email!,
            style:
            TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
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
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          isDark ? cs.surfaceContainerHighest : const Color(0xFF2D515C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
              isDark ? cs.onSurfaceVariant : Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                      isDark ? cs.onSurfaceVariant : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? cs.onSurfaceVariant.withValues(alpha: 0.7)
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? cs.onSurfaceVariant : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
