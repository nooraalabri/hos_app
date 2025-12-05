import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  String? hospitalName;
  String? _search;

  @override
  void initState() {
    super.initState();
    _loadHospitalData();
  }

  /// 🟡 نجلب hospitalName بدل hospitalId
  Future<void> _loadHospitalData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userSnap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userSnap.exists && mounted) {
      setState(() => hospitalName = userSnap.data()?['hospitalName']);
    }
  }

  /// 🔥 جلب المواعيد الخاصة بالمستشفى باستخدام hospitalName
  Stream<List<Map<String, dynamic>>> getReports() async* {
    if (hospitalName == null) yield [];

    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('hospitalName', isEqualTo: hospitalName)
        .orderBy('createdAt', descending: true)
        .get();

    yield snap.docs.map((e) => e.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t.patientReports),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),

      body: hospitalName == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
          stream: getReports(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());

            final data = snap.data!;
            if (data.isEmpty) return Center(child: Text(t.no_data));

            final filtered = data.where((r) =>
            _search == null ||
                (r['patientName'] ?? "")
                    .toLowerCase()
                    .contains(_search!.toLowerCase())
            ).toList();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔍 Search
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: t.search_patient,
                      filled: true,
                      fillColor: cs.surface.withValues(alpha: .15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _search = v.trim().isEmpty ? null : v),
                  ),

                  const SizedBox(height: 16),

                  // 📌 List
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final r = filtered[i];

                        final date = (r['createdAt'] is Timestamp)
                            ? (r['createdAt'] as Timestamp)
                            .toDate()
                            .toString()
                            .split(" ")
                            .first
                            : "-";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _item(context, t.patient, r['patientName']),
                                _item(context, t.doctor, r['doctorName']),
                                _item(context, t.hospital, r['hospitalName']),
                                _item(context, t.diagnosis, r['diagnosis']),
                                _item(context, t.date, date),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }

  Widget _item(BuildContext ctx, String title, data) {
    final cs = Theme.of(ctx).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$title: ${data ?? '-'}",
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: .85),
          fontSize: 15,
        ),
      ),
    );
  }
}
