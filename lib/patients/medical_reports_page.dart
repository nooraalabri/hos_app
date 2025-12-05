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

  // ===================== GET DOCTOR NAME =====================
  Future<String> _getDoctorName(String doctorId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
    return doc.exists ? (doc.data()?['name'] ?? doctorId) : doctorId;
  }

  // ===================== FIXED — GET HOSPITAL NAME =====================
  Future<String> _getHospitalName(String appointmentId) async {
    final appoint = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .get();

    if (!appoint.exists) return 'Unknown Hospital';

    final hospId = appoint.data()?['hospitalId'];
    if (hospId == null) return 'Unknown Hospital';

    // 🔥 هنا التعديل (بدل hospitals → users)
    final hosp = await FirebaseFirestore.instance
        .collection('users')
        .doc(hospId)
        .get();

    if (!hosp.exists) return 'Unknown Hospital';

    // 🔥 تأكيد أن الحقل المستخدم هو name
    return hosp.data()?['name'] ?? 'Unknown Hospital';
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
                  Text(t.medicalReports,
                      style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600,color: cs.onSurface)),

                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, c) =>
                    c.maxWidth > 600
                        ? Row(children: _buildFilters(context, t))
                        : Column(children: _buildFilters(context, t)),
                  ),

                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => setState(() {}), child: Text(t.send)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===================== REPORT LIST =====================
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: col.snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return Center(child:CircularProgressIndicator(color: cs.primary));
                  if (snap.data!.docs.isEmpty) return Center(child: Text(t.noReports));

                  final items = snap.data!.docs.map((e) => e.data()).where((r) {
                    final date = (r['createdAt'] is Timestamp)
                        ? (r['createdAt'] as Timestamp).toDate()
                        : DateTime.tryParse(r['createdAt'] ?? '');

                    return _day == null || (date != null &&
                        date.toString().startsWith(_day.toString().split(' ').first));
                  }).toList();

                  if (items.isEmpty) return Center(child: Text(t.noReports));

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
                          if (!snap2.hasData) return LinearProgressIndicator();

                          final doctor = snap2.data![0];
                          final hospital = snap2.data![1];

                          if (_hospital != null && !hospital.toLowerCase().contains(_hospital!.toLowerCase())) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? cs.surfaceContainerHighest : const Color(0xFF2D515C),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${t.hospital}: $hospital",style: TextStyle(fontWeight: FontWeight.bold,color:isDark? cs.onSurface: Colors.white,fontSize: 16)),
                                const SizedBox(height: 6),

                                Text("${t.doctor}: $doctor",style: TextStyle(color:isDark? cs.onSurface.withValues(alpha:.7):Colors.white70)),
                                const SizedBox(height: 6),

                                Text("${t.report}:",style: TextStyle(fontWeight: FontWeight.w600,color:isDark?cs.onSurface:Colors.white)),
                                const SizedBox(height: 4),

                                Text(r['report'] ?? '-',style: TextStyle(color:isDark?cs.onSurface:Colors.white,height:1.4)),
                                const SizedBox(height: 8),

                                Text("${t.date}: ${(r['createdAt'] is Timestamp)?(r['createdAt'] as Timestamp).toDate().toString().split(" ").first:"-"}",
                                  style: TextStyle(color:isDark?cs.onSurface.withValues(alpha:.6):Colors.white60,fontSize:13),
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // ===================== FILTER UI =====================
  List<Widget> _buildFilters(BuildContext context, AppLocalizations t) {
    final cs = Theme.of(context).colorScheme;

    return [
      Expanded(
        child: InkWell(
          onTap: () async {
            final d = await showDatePicker(
                context: context, firstDate: DateTime.now().subtract(const Duration(days:365)),
                lastDate: DateTime.now(), initialDate:_day ?? DateTime.now());

            if (d!=null) setState(()=>_day=d);
          },
          child: Container(
            padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),
            decoration:BoxDecoration(color:cs.surfaceContainerHighest,borderRadius:BorderRadius.circular(14)),
            child:Text(_day==null? t.appointmentDay:_day.toString().split(' ').first,style:TextStyle(color:cs.onSurface)),
          ),
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: TextField(
          decoration: InputDecoration(
            hintText:t.hospitalName,filled:true,fillColor:cs.surfaceContainerHighest,
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),
          ),
          onChanged:(v)=>setState(()=>_hospital=v.trim().isEmpty?null:v.trim()),
        ),
      ),
    ];
  }
}
