import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/notify_service.dart';

class ApproveHospitalsScreen extends StatelessWidget {
  const ApproveHospitalsScreen({super.key});

  Future<void> _decide(
      BuildContext context,
      String id,
      Map<String, dynamic> data,
      bool approve,
      ) async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
            backgroundColor:
            approve ? Colors.green : theme.colorScheme.error,
            content: Text(
              approve
                  ? '${t.hospital_approved_msg}: $hospitalName'
                  : '${t.hospital_rejected_msg}: $hospitalName',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.error,
            content: Text(
              '${t.error}: $e',
              style: TextStyle(color: theme.colorScheme.onError),
            ),
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(
      BuildContext context, String label, dynamic value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : "—",
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Text(
          t.hospital_approval_requests,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FS.pendingHospitalsStream(),
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
                "${t.error}: ${snap.error}",
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Text(
                t.no_pending_hospitals,
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
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data();

              return Card(
                color: theme.colorScheme.primary,
                shadowColor: theme.shadowColor.withValues(alpha: 0.3),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['name'] ?? '',
                        style: TextStyle(
                          fontSize: 20,
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),
                      _buildDetailRow(context, t.email, m['email']),
                      _buildDetailRow(context, t.phone, m['phone']),
                      _buildDetailRow(context, t.license_number, m['licenseNumber']),
                      _buildDetailRow(context, t.cr_number, m['crNumber']),
                      _buildDetailRow(context, t.location_label, m['location']),
                      _buildDetailRow(context, t.website, m['website']),
                      _buildDetailRow(context, t.created_at,
                          m['createdAt']?.toDate()?.toString()),

                      const SizedBox(height: 10),

                      if (m['licenseImage'] != null &&
                          m['licenseImage'].toString().isNotEmpty)
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
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // APPROVE
                          ElevatedButton.icon(
                            onPressed: () =>
                                _decide(context, d.id, m, true),
                            icon: Icon(Icons.check,
                                color: theme.colorScheme.onPrimary),
                            label: Text(
                              t.accept,
                              style: TextStyle(
                                  color: theme.colorScheme.onPrimary),
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

                          // REJECT
                          ElevatedButton.icon(
                            onPressed: () =>
                                _decide(context, d.id, m, false),
                            icon: Icon(Icons.close,
                                color: theme.colorScheme.onPrimary),
                            label: Text(
                              t.reject,
                              style: TextStyle(
                                  color: theme.colorScheme.onPrimary),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
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
