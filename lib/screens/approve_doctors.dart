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
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<Map<String, dynamic>?>(
      future: FS.hospitalForAdmin(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }

        if (!snap.hasData || snap.data == null) {
          return Scaffold(
            body: Center(
              child: Text(
                t.no_data,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }

        final hospitalId = snap.data!['id'];

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.primary,
            title: Text(
              t.doctor_approval_requests,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
          ),

          body: StreamBuilder(
            stream: FS.pendingDoctorsStream(hospitalId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                );
              }

              if (snap.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snap.error}",
                    style: theme.textTheme.bodyMedium!
                        .copyWith(color: theme.colorScheme.error),
                  ),
                );
              }

              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    t.no_pending_doctors,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.hintColor,
                    ),
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
                    color: theme.cardColor,
                    shadowColor: theme.shadowColor.withValues(alpha:0.2),
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
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: theme.hintColor,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ===== ACTION BUTTONS =====
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

                                  await NotifyService.sendEmail(
                                    to: email,
                                    subject: t.approved_email_subject,
                                    text:
                                    "${t.approved_email_text}\n\n${t.hospital_admin}",
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor:
                                      theme.colorScheme.primary,
                                      content: Text(
                                        '${t.doctor_approved_msg} - $name',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  t.accept,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
                                      backgroundColor:
                                      theme.colorScheme.errorContainer,
                                      content: Text(
                                        '${t.doctor_rejected_msg} - $name',
                                        style: TextStyle(
                                          color:
                                          theme.colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  theme.colorScheme.errorContainer,
                                  foregroundColor:
                                  theme.colorScheme.onErrorContainer,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  t.reject,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
