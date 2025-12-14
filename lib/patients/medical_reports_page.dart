// lib/patients/medical_reports_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'patient_drawer.dart';
import 'ui.dart';

class MedicalReportsPage extends StatefulWidget {
  static const route = '/patient/reports';
  const MedicalReportsPage({super.key});

  @override
  State<MedicalReportsPage> createState() => _MedicalReportsPageState();
}

class _MedicalReportsPageState extends State<MedicalReportsPage> {
  DateTime? _day;
  String? _hospital;

  Future<String> _getDoctorName(String doctorId) async {
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
    return doc.exists ? (doc.data()?['name'] ?? doctorId) : doctorId;
  }

  Future<String> _getHospitalName(String appointmentId) async {
    final appoint = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .get();
    if (appoint.exists) {
      final hospId = appoint.data()?['hospitalId'];
      if (hospId != null) {
        final hosp = await FirebaseFirestore.instance
            .collection('hospitals')
            .doc(hospId)
            .get();
        return hosp.exists
            ? (hosp.data()?['name'] ?? 'Unknown Hospital')
            : 'Unknown Hospital';
      }
    }
    return 'Unknown Hospital';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final col = FirebaseFirestore.instance
        .collection('reports')
        .where('patientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return AppScaffold(
      title: AppLocalizations.of(context)!.medical_reports,
      drawer: const PatientDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ====== الفلترة ======
            PrimaryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.medical_reports,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return isWide
                          ? Row(
                        children: _buildFilters(isWide: true),
                      )
                          : Column(
                        children: _buildFilters(isWide: false),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(text: AppLocalizations.of(context)!.send, onPressed: () => setState(() {})),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ====== عرض التقارير ======
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: col.snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                        CircularProgressIndicator(color: Color(0xFF2D515C)));
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)!.no_reports));
                  }

                  final items = snap.data!.docs.map((e) => e.data()).where((r) {
                    final createdAt = r['createdAt'];
                    DateTime? date;
                    if (createdAt is Timestamp) {
                      date = createdAt.toDate();
                    } else if (createdAt is String) {
                      date = DateTime.tryParse(createdAt);
                    }

                    final matchesDay = _day == null ||
                        (date != null &&
                            date
                                .toString()
                                .startsWith(_day!.toString().split(' ').first));

                    return matchesDay;
                  }).toList();

                  if (items.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)!.no_reports));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final r = items[i];
                      return FutureBuilder(
                        future: Future.wait([
                          _getDoctorName(r['doctorId'] ?? ''),
                          _getHospitalName(r['appointmentId'] ?? ''),
                        ]),
                        builder: (context, snap2) {
                          if (!snap2.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: LinearProgressIndicator(),
                            );
                          }

                          final doctorName = snap2.data![0];
                          final hospitalName = snap2.data![1];

                          final matchesHospital = _hospital == null ||
                              hospitalName
                                  .toLowerCase()
                                  .contains(_hospital!.toLowerCase());

                          if (!matchesHospital) return const SizedBox();

                          return Container(
                            width: double.infinity, // ✅ يجعل العرض أوتو بعرض الجهاز
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D515C),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hospital: $hospitalName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Doctor: $doctorName',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Report:',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  r['report'] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: ${(r['createdAt'] is Timestamp) ? (r['createdAt'] as Timestamp).toDate().toString().split(" ").first : "-"}',
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilters({required bool isWide}) {
    final dateFilter = InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          initialDate: _day ?? DateTime.now(),
        );
        if (d != null) setState(() => _day = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _day == null ? AppLocalizations.of(context)!.appointment_day : _day!.toString().split(' ').first,
        ),
      ),
    );

    final hospitalFilter = TextField(
      decoration: input(AppLocalizations.of(context)!.hospital_name_filter),
      onChanged: (v) =>
          setState(() => _hospital = v.trim().isEmpty ? null : v.trim()),
    );

    if (isWide) {
      return [
        Expanded(child: dateFilter),
        const SizedBox(width: 12),
        Expanded(child: hospitalFilter),
      ];
    } else {
      return [
        dateFilter,
        const SizedBox(height: 12),
        hospitalFilter,
      ];
    }
  }
}
