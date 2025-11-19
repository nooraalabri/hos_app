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

    // استلام بيانات المريض
    final Map<String, dynamic> data =
    (ModalRoute.of(context)?.settings.arguments
    as Map<String, dynamic>? ??
        {});

    final patientId = data['uid'] ?? data['id'] ?? data['patientId'] ?? '';

    if (patientId.isEmpty) {
      return AppScaffold(
        title: t.patientQr,
        body: Center(
          child: Text(
            t.patientIdNotFound,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ),
      );
    }

    // رابط بيانات المريض
    final url =
        'https://hospital-appointment-51250.web.app/patient.html?id=$patientId';

    return AppScaffold(
      title: t.patientQr,
      body: Center(
        child: PrimaryCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== QR CODE =====
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: AppColors.white,
                ),
              ),

              const SizedBox(height: 20),

              // ===== Scan text =====
              Text(
                t.scanQr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              // ===== URL =====
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.light,
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
