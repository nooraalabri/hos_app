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
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(doctorId)
        .get();

    return doc.exists ? (doc.data()?['name'] ?? doctorId) : doctorId;
  }

  Future<String> _getHospitalName(String appointmentId) async {
    final appoint = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .get();

    if (!appoint.exists) return 'Unknown Hospital';

    final hospId = appoint.data()?['hospitalId'];
    if (hospId == null) return 'Unknown Hospital';

    final hosp = await FirebaseFirestore.instance
        .collection('hospitals')
        .doc(hospId)
        .get();

    return hosp.exists
        ? (hosp.data()?['name'] ?? 'Unknown Hospital')
        : 'Unknown Hospital';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final col = FirebaseFirestore.instance
        .collection('reports')
        .where('patientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return AppScaffold(
      title: t.medicalReports,
      drawer: const PatientDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===================== FILTERS =====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.medicalReports,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return isWide
                          ? Row(children: _buildFilters(context, t))
                          : Column(children: _buildFilters(context, t));
                    },
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text(t.send),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===================== REPORTS LIST =====================
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: col.snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    );
                  }

                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        t.noReports,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  }

                  final items = snap.data!.docs
                      .map((e) => e.data())
                      .where((r) {
                    final createdAt = r['createdAt'];
                    DateTime? date;

                    if (createdAt is Timestamp) {
                      date = createdAt.toDate();
                    } else if (createdAt is String) {
                      date = DateTime.tryParse(createdAt);
                    }

                    final matchesDay = _day == null ||
                        (date != null &&
                            date.toString().startsWith(
                                _day!.toString().split(' ').first));

                    return matchesDay;
                  })
                      .toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        t.noReports,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    );
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

                          if (!matchesHospital) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? cs.surfaceContainerHighest
                                  : const Color(0xFF2D515C),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  cs.shadow.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.hospital}: $hospitalName',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? cs.onSurface
                                        : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${t.doctor}: $doctorName',
                                  style: TextStyle(
                                    color: isDark
                                        ? cs.onSurface.withValues(alpha: .7)
                                        : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${t.report}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                    isDark ? cs.onSurface : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r['report'] ?? '-',
                                  style: TextStyle(
                                    color: isDark
                                        ? cs.onSurface
                                        : Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${t.date}: ${(r['createdAt'] is Timestamp) ? (r['createdAt'] as Timestamp).toDate().toString().split(" ").first : "-"}',
                                  style: TextStyle(
                                    color: isDark
                                        ? cs.onSurface.withValues(alpha: .6)
                                        : Colors.white60,
                                    fontSize: 13,
                                  ),
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

  // ===================== FILTER WIDGETS =====================
  List<Widget> _buildFilters(BuildContext context, AppLocalizations t) {
    final cs = Theme.of(context).colorScheme;

    return [
      // ***** Date Filter *****
      Expanded(
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime.now().subtract(
                const Duration(days: 365),
              ),
              lastDate: DateTime.now(),
              initialDate: _day ?? DateTime.now(),
            );

            if (picked != null) {
              setState(() => _day = picked);
            }
          },
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _day == null
                  ? t.appointmentDay
                  : _day!.toString().split(' ').first,
              style: TextStyle(color: cs.onSurface),
            ),
          ),
        ),
      ),

      const SizedBox(width: 12),

      // ***** Hospital Filter *****
      Expanded(
        child: TextField(
          decoration: InputDecoration(
            hintText: t.hospitalName,
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) {
            setState(() {
              _hospital = v.trim().isEmpty ? null : v.trim();
            });
          },
        ),
      ),
    ];
  }
}
