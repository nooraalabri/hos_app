import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'ui.dart';

class QRPage extends StatelessWidget {
  static const route = '/patient/qr';
  const QRPage({super.key});

  @override
  Widget build(BuildContext context) {
    //  استقبال بيانات المريض من صفحة البروفايل
    final Map<String, dynamic> data =
    (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {});

    //  نحاول نأخذ الـ UID الصحيح للمريض
    final patientId = data['uid'] ?? data['id'] ?? data['patientId'] ?? '';

    if (patientId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            ' Patient ID not found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    //  عنوان صفحة المريض على Firebase Hosting
    // = غيّري هذا الرابط حسب اسم مشروعك في Firebase Hosting
    final url =
        'https://hospital-appointment-51250.web.app/patient.html?id=$patientId';

    return AppScaffold(
      title: 'Patient QR Code',
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
              const Text(
                'Scan this QR code to view patient profile',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
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
