import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'change_password.dart';

class SettingsScreen extends StatelessWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(color: cs.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: cs.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------------- LANGUAGE ----------------
            DropdownButtonFormField<String>(
              value: appProvider.language,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.language,
                labelStyle: TextStyle(color: cs.onSurface),
                filled: true,

                // surfaceVariant مُهمل → استبداله بـ surfaceContainerHighest
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: cs.surface,
              items: const [
                DropdownMenuItem(value: "en", child: Text("English")),
                DropdownMenuItem(value: "ar", child: Text("العربية")),
              ],
              onChanged: (value) async {
                if (value != null) {
                  await Provider.of<AppProvider>(context, listen: false)
                      .changeLanguage(value);
                }
              },
            ),

            const SizedBox(height: 20),

            // ---------------- DARK MODE SWITCH ----------------
            SwitchListTile(
              title: Text(
                AppLocalizations.of(context)!.dark_mode,
                style: TextStyle(color: cs.onSurface),
              ),
              value: appProvider.isDarkMode,
              onChanged: (value) => appProvider.toggleDarkMode(value),
              secondary: Icon(Icons.nightlight_round, color: cs.onSurface),
              activeColor: cs.primary,
            ),

            const Divider(height: 40),

            // ---------------- CHANGE PASSWORD ----------------
            ListTile(
              leading: Icon(Icons.lock, color: cs.primary),
              title: Text(
                AppLocalizations.of(context)!.change_password,
                style: TextStyle(color: cs.onSurface),
              ),
              onTap: () {
                Navigator.pushNamed(context, ChangePasswordScreen.route);
              },
            ),

            const Spacer(),

            // ---------------- LOGOUT BUTTON ----------------
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: Text(AppLocalizations.of(context)!.logout),
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
