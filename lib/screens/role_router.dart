import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hos_app/screens/pending_approval.dart';

import '../patients/patient_home.dart';
import '../services/firestore_service.dart';
import '../l10n/app_localizations.dart';
import 'doctor_home.dart';
import '../pages/hospital_admin_home.dart';
import '../pages/head_admin_home.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(loc?.login ?? 'Not logged in'),
        ),
      );
    }

    final stream = FS.users.doc(user.uid).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            body: Center(
              child: Text(loc?.no_data ?? 'User profile not found'),
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
              body: Center(
                child: Text(loc?.error_occurred ?? 'Unknown role'),
              ),
            );
        }
      },
    );
  }
}
