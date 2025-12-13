import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';

import '../screens/pending_approval.dart';
import '../patients/patient_home.dart';
import '../services/firestore_service.dart';
import 'doctor_home.dart';
import '../pages/hospital_admin_home.dart';
import '../pages/head_admin_home.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final user = FirebaseAuth.instance.currentUser;

    // ---------------- Not Logged In ----------------
    if (user == null) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Text(
            t.notLoggedIn,
            style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
          ),
        ),
      );
    }

    final stream = FS.users.doc(user.uid).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: cs.surface,
            body: Center(
              child: CircularProgressIndicator(color: cs.primary),
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            backgroundColor: cs.surface,
            body: Center(
              child: Text(
                t.profileNotFound,
                style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
              ),
            ),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final role = (data['role'] ?? '').toString();
        final approved = (data['approved'] ?? false) == true;

        switch (role) {
          case 'patient':
            return const PatientHome();

          case 'doctor':
            if (!approved) return const PendingApprovalScreen();
            return DoctorHome(doctorId: user.uid);

          case 'hospitaladmin':
            if (!approved) return const PendingApprovalScreen();
            return const HospitalAdminHome();

          case 'headadmin':
            return const HeadAdminHome();

          default:
            return Scaffold(
              backgroundColor: cs.surface,
              body: Center(
                child: Text(
                  t.unknownRole,
                  style:
                  theme.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                ),
              ),
            );
        }
      },
    );
  }
}
