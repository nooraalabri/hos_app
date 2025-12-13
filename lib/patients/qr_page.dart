import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'ui.dart';
import '../l10n/app_localizations.dart';
import '../routes.dart';

class QRPage extends StatelessWidget {
  static const route = '/patient/qr';
  const QRPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // استلام بيانات المريض من الـ LoginScreen (Face Login)
    final Map<String, dynamic> data =
    (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {});

    final patientId = data['uid'] ?? data['id'] ?? data['patientId'] ?? '';
    final bool fromFace = data['fromFace'] == true; // لو جاي من Face Recognition

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

    // 🔗 رابط صفحة بيانات المريض في الويب
    final url = "https://hospital-appointment-51250.web.app/patient.html?id=$patientId";

    return PopScope(
      canPop: !fromFace, // يمنع الرجوع لو جاء من Face Login

      onPopInvokedWithResult: (didPop, result) {
        if (fromFace) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      },

      child: AppScaffold(
        title: t.patientQr,
        drawer: fromFace ? null : null, // لو من الفيس لا Drawer

        body: Center(
          child: PrimaryCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ========= QR CODE =========
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 250,           // 👈 كبرت QR شوي
                    backgroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  t.scanQr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                SelectableText(
                  url,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.light,
                    decoration: TextDecoration.underline,
                  ),
                ),

                const SizedBox(height: 30),

                // ================= BUTTON BEHAVIOR =================
                fromFace
                    ? ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.login, (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.dark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: const Text("Back to Login"),
                )
                    : ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.dark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: const Text("Back"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
