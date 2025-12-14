import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../routes.dart';
import '../screens/settings_screen.dart';
import '../screens/chatbot_screen.dart';

class HeadAdminHome extends StatelessWidget {
  const HeadAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Head Admin'),
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

            _HomeTile(
              title: 'Review Hospitals',
              subtitle: 'Accept or Reject new hospital requests',
              icon: Icons.fact_check_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.approveHospitals,
              ),
            ),

            const SizedBox(height: 12),

            _HomeTile(
              title: 'Reports',
              subtitle: 'Weekly / Monthly / Yearly stats',
              icon: Icons.pie_chart_outline,
              onTap: () => Navigator.pushNamed(context, AppRoutes.headAdminReports),
            ),

            const SizedBox(height: 12),

            _HomeTile(
              title: 'Social Media',
              subtitle: 'Post to Instagram, Facebook & Twitter',
              icon: Icons.share,
              onTap: () => Navigator.pushNamed(context, AppRoutes.socialMedia),
            ),

            const SizedBox(height: 12),

            _HomeTile(
              title: 'Chatbot',
              subtitle: 'Get help and guidance',
              icon: Icons.smart_toy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                );
              },
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () => AuthService.logoutAndGoWelcome(context),
              child: const Text('Logout'),
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
                  Text(subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                      )),
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
