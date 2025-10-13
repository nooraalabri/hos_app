import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class HeadAdminReportsScreen extends StatefulWidget {
  const HeadAdminReportsScreen({super.key});

  @override
  State<HeadAdminReportsScreen> createState() => _HeadAdminReportsScreenState();
}

class _HeadAdminReportsScreenState extends State<HeadAdminReportsScreen> {
  ReportPeriod period = ReportPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: FutureBuilder<Map<String, int>>(
        future: FS.statsForHeadAdmin(period: period),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final m = snap.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(), // 👈 يمنع التمرير الداخلي
                  shrinkWrap: true, // 👈 يخلي Grid يأخذ حجمه فقط
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _statCard('Hospitals (approved)', m['hospitalsApproved'] ?? 0,
                        Icons.local_hospital, Colors.green),
                    _statCard('Hospitals (pending)', m['hospitalsPending'] ?? 0,
                        Icons.pending, Colors.orange),
                    _statCard('Doctors (approved)', m['doctorsApproved'] ?? 0,
                        Icons.medical_information, Colors.blue),
                    _statCard('Doctors (pending)', m['doctorsPending'] ?? 0,
                        Icons.pending_actions, Colors.red),
                    _statCard('Patients (total)', m['patientsTotal'] ?? 0,
                        Icons.people, Colors.purple),
                    _statCard('New users', m['newUsers'] ?? 0,
                        Icons.person_add, Colors.teal),
                    _statCard('New hospitals', m['newHospitals'] ?? 0,
                        Icons.apartment, Colors.brown),
                    _statCard('Appointments', m['appointments'] ?? 0,
                        Icons.event_available, Colors.indigo),
                  ],
                ),

                const SizedBox(height: 20),

                SegmentedButton<ReportPeriod>(
                  segments: const [
                    ButtonSegment(value: ReportPeriod.weekly, label: Text('Weekly')),
                    ButtonSegment(value: ReportPeriod.monthly, label: Text('Monthly')),
                    ButtonSegment(value: ReportPeriod.yearly, label: Text('Yearly')),
                  ],
                  selected: {period},
                  onSelectionChanged: (s) => setState(() => period = s.first),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
