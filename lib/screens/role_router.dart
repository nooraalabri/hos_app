import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../pages/patient_home.dart';
import '../pages/doctor_home.dart';
import '../pages/hospital_admin_home.dart';
import '../pages/head_admin_home.dart';
import 'pending_screen.dart'; // تأكدي أن الملف موجود في نفس مجلد الشاشات

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    // نسمع لتغيرات الوثيقة مباشرة: لما الأدمن يوافق، تتحول الشاشة تلقائيًا
    final stream = FS.users.doc(user.uid).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('User profile not found')));
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final role = (data['role'] ?? '').toString();
        final approved = (data['approved'] ?? false) == true;

        switch (role) {
          case 'patient':
          // المريض ما يحتاج موافقة
            return const PatientHome();

          case 'doctor':
          // ينتظر موافقة Hospital Admin
            if (!approved) return const PendingScreen(forRole: 'Doctor');
            return const DoctorHome();

          case 'hospitaladmin':
          // ينتظر موافقة Head Admin على المستشفى
            if (!approved) return const PendingScreen(forRole: 'Hospital Admin');
            return const HospitalAdminHome();

          case 'headadmin':
            return const HeadAdminHome();

          default:
            return const Scaffold(body: Center(child: Text('Unknown role')));
        }
      },
    );
  }
}
