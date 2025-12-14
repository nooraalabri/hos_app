import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import 'ui.dart';
import 'patient_drawer.dart';

class QRPage extends StatelessWidget {
  static const route = '/patient/qr';
  const QRPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get patient ID from FirebaseAuth first, then try route arguments
    final currentUser = FirebaseAuth.instance.currentUser;
    final patientId = currentUser?.uid ?? 
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['uid'] ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['id'] ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['patientId'] ??
        '';

    if (patientId.isEmpty) {
      return AppScaffold(
        title: AppLocalizations.of(context)!.patient_qr_code,
        drawer: const PatientDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.patient_id_not_found,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please make sure you are logged in',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    //  عنوان صفحة المريض على Firebase Hosting
    // = غيّري هذا الرابط حسب اسم مشروعك في Firebase Hosting
    final url =
        'https://hospital-appointment-51250.web.app/patient.html?id=$patientId';

    return AppScaffold(
      title: AppLocalizations.of(context)!.patient_qr_code,
      drawer: const PatientDrawer(),
      body: Center(
        child: PrimaryCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //  كود QR يحوي رابط صفحة المريض
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.scan_qr_view_profile,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),

              //  عرض الرابط أسفل الكود (قابل للنسخ)
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
