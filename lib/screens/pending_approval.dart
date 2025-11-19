import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';

import '../routes.dart';
import '../services/auth_service.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _checking = false;
  String? _error;

  Future<void> _logout() async {
    try {
      await AuthService.logout();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
  }

  Future<void> _checkAgain() async {
    final t = AppLocalizations.of(context)!;

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
        return;
      }

      final uid = user.uid;
      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userSnap = await usersRef.get();

      if (!userSnap.exists) {
        setState(() => _error = t.userProfileNotFound);
        return;
      }

      final data = userSnap.data()!;
      final role = (data['role'] ?? '').toString();
      final approved = (data['approved'] ?? false) == true;

      if (approved) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleRouter, (_) => false);
        return;
      }

      // 🔹 Hospital Admin auto-approval when hospital status changes
      if (role == 'hospitaladmin') {
        final hospId = data['hospitalId']?.toString();
        if (hospId != null && hospId.isNotEmpty) {
          final hospSnap = await FirebaseFirestore.instance
              .collection('hospitals')
              .doc(hospId)
              .get();

          final hospApproved =
              hospSnap.exists && (hospSnap.data()?['status'] == 'approved');

          if (hospApproved) {
            await usersRef.set({'approved': true}, SetOptions(merge: true));
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleRouter, (_) => false);
            return;
          }
        }
      }

      setState(() => _error = t.stillPending);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.pendingApprovalTitle,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        automaticallyImplyLeading: false,
      ),

      backgroundColor: theme.scaffoldBackgroundColor,

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 96,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 16),

            Text(
              t.requestSubmitted,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),
            Text(
              t.reviewingRegistration,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            if (email.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "${t.signedInAs} $email",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _checking ? null : _checkAgain,
                    icon: _checking
                        ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                        : const Icon(Icons.refresh),
                    label: Text(t.checkAgain),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: Text(t.logout),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
