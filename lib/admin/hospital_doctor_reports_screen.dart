import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/admin_drawer.dart';
import '../../services/firestore_service.dart';

class HospitalDoctorReportsScreen extends StatefulWidget {
  static const route = '/hospital/doctor-reports';
  const HospitalDoctorReportsScreen({super.key});

  @override
  State<HospitalDoctorReportsScreen> createState() => _HospitalDoctorReportsScreenState();
}

class _HospitalDoctorReportsScreenState extends State<HospitalDoctorReportsScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Reports')),
      drawer: const AdminDrawer(),
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
            return const Center(child: Text('No doctors found'));
          }

          final doctors = snap.data!.docs
              .map((d) => {'id': d.id, ...d.data()})
              .where((r) =>
          _search == null ||
              (r['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_search!.toLowerCase()))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by doctor name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (v) =>
                      setState(() => _search = v.trim().isEmpty ? null : v.trim()),
                ),
                const SizedBox(height: 16),

                // ===== List of Doctors =====
                Expanded(
                  child: ListView.builder(
                    itemCount: doctors.length,
                    itemBuilder: (ctx, i) {
                      final d = doctors[i];
                      final name = d['name'] ?? 'Unknown';
                      final email = d['email'] ?? '';
                      final specialization = d['specialization'] ?? '—';
                      final doctorId = d['id'];

                      return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('appointments')
                            .where('doctorId', isEqualTo: doctorId)
                            .get(),
                        builder: (ctx, appSnap) {
                          int total = appSnap.data?.docs.length ?? 0;
                          int completed = appSnap.data?.docs
                              .where((a) => a['status'] == 'completed')
                              .length ??
                              0;

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
                                  Text('$name',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('$email'),
                                  const SizedBox(height: 4),
                                  Text('Specialty: $specialization'),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      _statBox('Appointments', total),
                                      _statBox('Completed', completed),
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

  Widget _statBox(String title, int value) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D515C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value.toString(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
