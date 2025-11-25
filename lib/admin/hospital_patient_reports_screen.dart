import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../l10n/app_localizations.dart';

class HospitalPatientReportsScreen extends StatefulWidget {
  static const route = '/hospital/patient-reports';
  const HospitalPatientReportsScreen({super.key});

  @override
  State<HospitalPatientReportsScreen> createState() =>
      _HospitalPatientReportsScreenState();
}

class _HospitalPatientReportsScreenState
    extends State<HospitalPatientReportsScreen> {
  String? hospId;
  String? _search;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // === GET hospitalId FROM USERS ===
    FS.users.doc(uid).get().then((doc) {
      if (doc.exists) {
        final hid = doc.data()?['hospitalId'];
        if (mounted) setState(() => hospId = hid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // back button
          },
        ),
        title: Text(t.patient_profile),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),

      // 🔥 Removed Drawer (no menu)
      // drawer: const AdminDrawer(),

      body: hospId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collectionGroup('reports')
            .where('hospitalId', isEqualTo: hospId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Text(t.no_data));
          }

          final items = snap.data!.docs
              .map((d) => d.data())
              .where(
                (r) =>
            _search == null ||
                (r['patientName'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_search!.toLowerCase()),
          )
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔍 Search
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: t.search_patient,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: cs.surface.withValues(alpha: 0.2),
                  ),
                  onChanged: (v) => setState(() {
                    _search = v.trim().isEmpty ? null : v.trim();
                  }),
                ),

                const SizedBox(height: 16),

                // 📋 Reports List
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final r = items[i];

                      final date = (r['createdAt'] is Timestamp)
                          ? (r['createdAt'] as Timestamp)
                          .toDate()
                          .toString()
                          .split(' ')
                          .first
                          : '-';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        color: cs.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t.patient}: ${r['patientName'] ?? t.unknown}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                '${t.doctor}: ${r['doctorName'] ?? '-'}',
                                style: TextStyle(
                                  color: cs.onSurface
                                      .withValues(alpha: .8),
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                '${t.hospital}: ${r['hospitalName'] ?? '-'}',
                                style: TextStyle(
                                  color: cs.onSurface
                                      .withValues(alpha: .8),
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                '${t.diagnosis}: ${r['diagnosis'] ?? '-'}',
                                style: TextStyle(
                                  color: cs.onSurface
                                      .withValues(alpha: .8),
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                '${t.date}: $date',
                                style: TextStyle(
                                  color: cs.onSurface
                                      .withValues(alpha: .8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
