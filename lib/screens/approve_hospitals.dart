import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/notify_service.dart';

class ApproveHospitalsScreen extends StatelessWidget {
  const ApproveHospitalsScreen({super.key});

  Future<void> _decide(BuildContext context, String id, Map data, bool approve) async {
    await FS.decideHospital(hospitalId: id, approve: approve);
    final adminEmail = data['email'] as String?; // إيميل مسؤول المستشفى
    if (adminEmail != null) {
      await NotifyService.sendEmail(
        to: adminEmail,
        subject: approve ? 'Hospital Approved' : 'Hospital Rejected',
        text: approve
            ? 'Your hospital "${data['name']}" has been approved.'
            : 'Your hospital "${data['name']}" has been rejected.',
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Approved' : 'Rejected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accept or Reject (Hospitals)')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FS.pendingHospitalsStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No pending hospitals'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final d = docs[i];
              final m = d.data();
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                color: const Color(0xFF2D515C),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['name'] ?? 'Unnamed', style: const TextStyle(color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 6),
                      Text(m['email'] ?? '', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _decide(context, d.id, m, true),
                            child: const Text('Accept'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _decide(context, d.id, m, false),
                            child: const Text('Reject'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}
