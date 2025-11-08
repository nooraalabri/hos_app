import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../routes.dart';
import '../widgets/admin_drawer.dart';

class HospitalAdminHome extends StatelessWidget {
  const HospitalAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<Map<String, dynamic>?>(
      future: FS.hospitalForAdmin(uid),
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final data = snap.data;
        final name = (data?['name'] ?? 'Hospital Admin') as String;
        final status = (data?['status'] ?? 'pending') as String;

        return Scaffold(
          drawer: AdminDrawer(hospitalName: name),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2D515C),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                color: Color(0xFFE6EBEC),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Logout',
                onPressed: () => AuthService.logoutAndGoWelcome(context),
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
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
                title: 'My profile',
                subtitle: 'Hospital info & about',
                icon: Icons.person_outline,
                onTap: () => Navigator.pushNamed(context, AppRoutes.hospitalProfile),
              ),
              const SizedBox(height: 12),

              _HomeTile(
                title: 'My staff',
                subtitle: 'Manage doctors & details',
                icon: Icons.badge_outlined,
                onTap: () => Navigator.pushNamed(context, AppRoutes.myStaff),
              ),
              const SizedBox(height: 12),

              _HomeTile(
                title: 'Reports',
                subtitle: 'Weekly / Monthly / Yearly',
                icon: Icons.pie_chart_outline,
                onTap: () => Navigator.pushNamed(context, AppRoutes.hospitalReports),
              ),

              const SizedBox(height: 24),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2D515C),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.regDoctor),
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFFE6EBEC)),
            label: const Text(
              'Add doctor',
              style: TextStyle(
                color: Color(0xFFE6EBEC),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          leading: const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF2D515C),
            child: Icon(Icons.local_hospital, color: Colors.white),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF2D515C),
            ),
          ),
          subtitle: email == null
              ? null
              : Text(
            email!,
            style: const TextStyle(color: Colors.black54),
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
                  Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
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
