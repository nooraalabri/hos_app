import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';

class HeadAdminHospitalDetailsScreen extends StatelessWidget {
  const HeadAdminHospitalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final col = FirebaseFirestore.instance
        .collection('hospitals')
        .where('status', isEqualTo: 'approved');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.hospitalsOverview,
          style: const TextStyle(color: Color(0xFF2D515C), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D515C)),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE6EBEC),

      body: StreamBuilder<QuerySnapshot>(
        stream: col.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Text(
                t.noApprovedHospitals,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;

              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final city = data['city'] ?? '';
              final phone = data['phone'] ?? '';

              return Card(
                color: const Color(0xFF2D515C),
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${t.email}: $email\n${t.phone}: $phone\n${t.city}: $city',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HospitalStatsDetails(
                          hospId: d.id,
                          hospName: name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------- DETAILS PAGE --------------------

class HospitalStatsDetails extends StatelessWidget {
  final String hospId;
  final String hospName;

  const HospitalStatsDetails({
    super.key,
    required this.hospId,
    required this.hospName,
  });

  Future<Map<String, int>> _load() async {
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('hospitalId', isEqualTo: hospId)
        .get();

    final doctors = users.docs.where((d) => d['role'] == 'doctor').length;
    final patients = users.docs.where((d) => d['role'] == 'patient').length;

    final appointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('hospitalId', isEqualTo: hospId)
        .get();

    return {
      'doctors': doctors,
      'patients': patients,
      'appointments': appointments.size,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${hospName} ${t.hospitalStats}",
          style: const TextStyle(color: Color(0xFF2D515C)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D515C)),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),

      backgroundColor: const Color(0xFFE6EBEC),

      body: FutureBuilder<Map<String, int>>(
        future: _load(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          if (!snap.hasData) {
            return Center(child: Text(t.noData));
          }

          final data = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _statTile(t.doctors, data['doctors'] ?? 0,
                  Icons.medical_information, Colors.blue),

              _statTile(t.patients, data['patients'] ?? 0,
                  Icons.people, Colors.purple),

              _statTile(t.appointments, data['appointments'] ?? 0,
                  Icons.event, Colors.teal),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile(String title, int value, IconData icon, Color color) {
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          "$value",
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
