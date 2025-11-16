import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.reports)),
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
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _statCard(t.hospitalsApproved,
                        m['hospitalsApproved'] ?? 0,
                        Icons.local_hospital, Colors.green),

                    _statCard(t.hospitalsPending,
                        m['hospitalsPending'] ?? 0,
                        Icons.pending, Colors.orange),

                    _statCard(t.doctorsApproved,
                        m['doctorsApproved'] ?? 0,
                        Icons.medical_information, Colors.blue),

                    _statCard(t.doctorsPending,
                        m['doctorsPending'] ?? 0,
                        Icons.pending_actions, Colors.red),

                    _statCard(t.patientsTotal,
                        m['patientsTotal'] ?? 0,
                        Icons.people, Colors.purple),

                    _statCard(t.newUsers,
                        m['newUsers'] ?? 0,
                        Icons.person_add, Colors.teal),

                    _statCard(t.newHospitals,
                        m['newHospitals'] ?? 0,
                        Icons.apartment, Colors.brown),

                    _statCard(t.appointments,
                        m['appointments'] ?? 0,
                        Icons.event_available, Colors.indigo),
                  ],
                ),

                const SizedBox(height: 20),

                SegmentedButton<ReportPeriod>(
                  segments: [
                    ButtonSegment(
                      value: ReportPeriod.weekly,
                      label: Text(t.weekly),
                    ),
                    ButtonSegment(
                      value: ReportPeriod.monthly,
                      label: Text(t.monthly),
                    ),
                    ButtonSegment(
                      value: ReportPeriod.yearly,
                      label: Text(t.yearly),
                    ),
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
