import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'ui.dart';
import '../l10n/app_localizations.dart';
class QRPage extends StatelessWidget {
  static const route = '/patient/qr';
  const QRPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // استلام بيانات المريض من البروفايل
    final Map<String, dynamic> data =
    (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {});

    // الحصول على UID الصحيح
    final patientId = data['uid'] ?? data['id'] ?? data['patientId'] ?? '';

    if (patientId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.patientQr)),
        body: Center(
          child: Text(
            t.patientIdNotFound,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // رابط صفحة المريض – ضعي رابط مشروعك هنا
    final url =
        'https://hospital-appointment-51250.web.app/patient.html?id=$patientId';

    return AppScaffold(
      title: t.patientQr,
      body: Center(
        child: PrimaryCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                t.scanQr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
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
