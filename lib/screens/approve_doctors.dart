import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

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
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || snap.data == null) {
          return const Scaffold(
              body: Center(child: Text("No hospital found for this admin")));
        }

        final hospitalId = snap.data!['id'];
        return Scaffold(
          appBar: AppBar(title: const Text("Accept or Reject (Doctors)")),
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
                return const Center(child: Text("No pending doctors"));
              }

              final docs = snap.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(d['name'] ?? "Doctor"),
                      subtitle: Text(d['email'] ?? ""),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => FS.decideDoctor(
                                doctorUid: docs[i].id, approve: true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => FS.decideDoctor(
                                doctorUid: docs[i].id, approve: false),
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
