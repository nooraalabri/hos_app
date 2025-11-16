import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/notify_service.dart';

class ApproveDoctorsScreen extends StatelessWidget {
  const ApproveDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<Map<String, dynamic>?>(
      future: FS.hospitalForAdmin(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData || snap.data == null) {
          return Scaffold(
            body: Center(
              child: Text(t.no_data),
            ),
          );
        }

        final hospitalId = snap.data!['id'];

        return Scaffold(
          appBar: AppBar(
            title: Text(t.doctor_approval_requests),
            centerTitle: true,
          ),
          body: StreamBuilder(
            stream: FS.pendingDoctorsStream(hospitalId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text("Error: ${snap.error}"));
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    t.no_pending_doctors,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                );
              }

              final docs = snap.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data();
                  final doctorId = docs[i].id;
                  final name = d['name'] ?? t.unknown;
                  final email = d['email'] ?? '';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // APPROVE
                              ElevatedButton(
                                onPressed: () async {
                                  await FS.decideDoctor(
                                    doctorUid: doctorId,
                                    approve: true,
                                  );

                                  // Email
                                  await NotifyService.sendEmail(
                                    to: email,
                                    subject: t.approved_email_subject,
                                    text:
                                    "${t.approved_email_text}\n\n${t.hospital_admin}",
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${t.doctor_approved_msg} - $name'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  t.accept,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // REJECT
                              ElevatedButton(
                                onPressed: () async {
                                  await FS.decideDoctor(
                                      doctorUid: doctorId, approve: false);

                                  await NotifyService.sendEmail(
                                    to: email,
                                    subject: t.rejected_email_subject,
                                    text:
                                    "${t.rejected_email_text}\n\n${t.hospital_admin}",
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${t.doctor_rejected_msg} - $name'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  t.reject,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
