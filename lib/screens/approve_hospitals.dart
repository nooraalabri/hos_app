import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/notify_service.dart';

class ApproveHospitalsScreen extends StatelessWidget {
  const ApproveHospitalsScreen({super.key});

  Future<void> _decide(
      BuildContext context, String id, Map<String, dynamic> data, bool approve) async {
    final t = AppLocalizations.of(context)!;

    try {
      await FS.decideHospital(hospitalId: id, approve: approve);

      final adminEmail = data['email'] as String?;
      final hospitalName = data['name'] ?? '';

      if (adminEmail != null && adminEmail.isNotEmpty) {
        await NotifyService.notifyHospitalDecision(
          toEmail: adminEmail,
          hospitalName: hospitalName,
          approved: approve,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? '${t.hospital_approved_msg}: $hospitalName'
                  : '${t.hospital_rejected_msg}: $hospitalName',
            ),
            backgroundColor: approve ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.error}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : "—",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    const darkColor = Color(0xFF2D515C);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.hospital_approval_requests,
          style: const TextStyle(
            color: darkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: darkColor),
      ),
      backgroundColor: const Color(0xFFE6EBEC),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FS.pendingHospitalsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text("${t.error}: ${snap.error}"));
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Text(
                t.no_pending_hospitals,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data();

              return Card(
                color: darkColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),
                      _buildDetailRow(t.email, m['email']),
                      _buildDetailRow(t.phone, m['phone']),
                      _buildDetailRow(t.license_number, m['licenseNumber']),
                      _buildDetailRow(t.cr_number, m['crNumber']),
                      _buildDetailRow(t.location_label, m['location']),
                      _buildDetailRow(t.website, m['website']),
                      _buildDetailRow(t.created_at, m['createdAt']?.toDate()?.toString()),

                      const SizedBox(height: 10),

                      if (m['licenseImage'] != null && m['licenseImage'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            m['licenseImage'],
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.black26,
                              alignment: Alignment.center,
                              child: Text(
                                t.image_not_available,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _decide(context, d.id, m, true),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: Text(
                              t.accept,
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _decide(context, d.id, m, false),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: Text(
                              t.reject,
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
  }
}
