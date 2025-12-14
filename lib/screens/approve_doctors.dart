import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/notify_service.dart';

class ApproveDoctorsScreen extends StatelessWidget {
  const ApproveDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          return const Scaffold(
            body: Center(
              child: Text("No hospital found for this admin"),
            ),
          );
        }

        final hospitalId = snap.data!['id'];

        return Scaffold(
          appBar: AppBar(
            title: const Text("Doctor Approval Requests"),
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
                return const Center(
                  child: Text(
                    "No pending doctor requests",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
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
                  final name = d['name'] ?? 'Unknown Doctor';
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
                              //  زر الـ Approve
                              ElevatedButton(
                                onPressed: () async {
                                  await FS.decideDoctor(
                                      doctorUid: doctorId, approve: true);

                                  //  إرسال إيميل للدكتور بعد الموافقة
                                  await NotifyService.sendEmail(
                                    to: email,
                                    subject: 'Doctor Account Approved',
                                    text: '''
Dear Dr. $name,

Your registration request has been approved by the hospital administration.
You can now log in to your account and start using the system.

Best regards,
Hospital Administration
''',
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Doctor "$name" has been APPROVED and notified by email.'),
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
                                child: const Text(
                                  "Accept",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              //  زر الـ Reject
                              ElevatedButton(
                                onPressed: () async {
                                  await FS.decideDoctor(
                                      doctorUid: doctorId, approve: false);

                                  //  إرسال إيميل رفض
                                  await NotifyService.sendEmail(
                                    to: email,
                                    subject: 'Doctor Account Rejected',
                                    text: '''
Dear Dr. $name,

We regret to inform you that your registration request has been rejected.
If you believe this was a mistake, please contact the hospital administration.

Best regards,
Hospital Administration
''',
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Doctor "$name" has been REJECTED and notified by email.'),
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
                                child: const Text(
                                  "Reject",
                                  style: TextStyle(
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
