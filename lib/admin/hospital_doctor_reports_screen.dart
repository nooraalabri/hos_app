import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../l10n/app_localizations.dart';

class HospitalDoctorReportsScreen extends StatefulWidget {
  static const route = '/hospital/doctor-reports';
  const HospitalDoctorReportsScreen({super.key});

  @override
  State<HospitalDoctorReportsScreen> createState() =>
      _HospitalDoctorReportsScreenState();
}

class _HospitalDoctorReportsScreenState
    extends State<HospitalDoctorReportsScreen> {
  String? hospId;
  String? _search;

  @override
  void initState() {
    super.initState();

    // === GET hospitalId FROM USERS ===
    final uid = FirebaseAuth.instance.currentUser!.uid;
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
            Navigator.of(context).pop(); // يرجع للصفحة السابقة
          },
        ),
        title: Text(t.doctor_profile),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),

      body: hospId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .where('hospitalId', isEqualTo: hospId)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Text(t.no_data));
          }

          final doctors = snap.data!.docs
              .map((d) => {'id': d.id, ...d.data()})
              .where(
                (r) =>
            _search == null ||
                (r['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_search!.toLowerCase()),
          )
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ===== SEARCH BOX =====
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: t.search_doctor,
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

                // ===== DOCTORS LIST =====
                Expanded(
                  child: ListView.builder(
                    itemCount: doctors.length,
                    itemBuilder: (ctx, i) {
                      final d = doctors[i];

                      final doctorId = d['id'];
                      final name = d['name'] ?? t.unknown;
                      final email = d['email'] ?? '';
                      final specialization =
                          d['specialization'] ?? '—';

                      return FutureBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('appointments')
                            .where('doctorId', isEqualTo: doctorId)
                            .get(),
                        builder: (ctx, appSnap) {
                          final allApps = appSnap.data?.docs ?? [];
                          final total = allApps.length;

                          final completed = allApps
                              .where((a) =>
                          (a.data()['status'] ?? '') ==
                              'completed')
                              .length;

                          return Card(
                            margin:
                            const EdgeInsets.only(bottom: 12),
                            color: cs.surface,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                      fontWeight:
                                      FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(
                                          alpha: .8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${t.specialization}: $specialization',
                                    style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(
                                          alpha: .8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      _statBox(context,
                                          t.appointments, total),
                                      _statBox(context,
                                          t.completed, completed),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== STAT BOX =====
  Widget _statBox(BuildContext context, String title, int value) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
