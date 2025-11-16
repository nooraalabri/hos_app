import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/admin_drawer.dart';
import '../../services/firestore_service.dart';
import '../../l10n/app_localizations.dart'; // ✅ لإضافة الترجمة

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
    FS.hospitalForAdmin(uid).then((d) {
      setState(() => hospId = d?['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // ✅ متغير الترجمة

    return Scaffold(
      appBar: AppBar(title: Text(t.patient_profile)), // ✅ "Patient Reports"
      drawer: const AdminDrawer(),
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
            return Center(child: Text(t.no_data)); // ✅ "No reports found"
          }

          final items = snap.data!.docs
              .map((d) => d.data())
              .where((r) =>
          _search == null ||
              (r['patientName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_search!.toLowerCase()))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔍 حقل البحث
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: t.search_patient, // ✅ "Search by patient name"
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (v) => setState(() =>
                  _search = v.trim().isEmpty ? null : v.trim()),
                ),
                const SizedBox(height: 16),

                // 📋 قائمة التقارير
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t.patient}: ${r['patientName'] ?? t.unknown}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text('${t.doctor}: ${r['doctorName'] ?? '-'}'),
                              const SizedBox(height: 4),
                              Text(
                                  '${t.hospital}: ${r['hospitalName'] ?? '-'}'),
                              const SizedBox(height: 4),
                              Text(
                                  '${t.diagnosis ?? "Diagnosis"}: ${r['diagnosis'] ?? '-'}'),
                              const SizedBox(height: 4),
                              Text('${t.date ?? "Date"}: $date'),
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
