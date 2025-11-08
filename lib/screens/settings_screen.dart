import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';
import 'change_password.dart';

class SettingsScreen extends StatelessWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: appProvider.language,
              decoration: const InputDecoration(labelText: "Language"),
              items: const [
                DropdownMenuItem(value: "en", child: Text("English")),
                DropdownMenuItem(value: "ar", child: Text("العربية")),
              ],
              onChanged: (value) {
                if (value != null) {
                  appProvider.changeLanguage(value);
                }
              },
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: appProvider.isDarkMode,
              onChanged: (value) {
                appProvider.toggleDarkMode(value);
              },
              secondary: const Icon(Icons.nightlight_round),
            ),
            const Divider(height: 40),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Change Password"),
              onTap: () {
                Navigator.pushNamed(context, ChangePasswordScreen.route);
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
