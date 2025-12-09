import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../l10n/app_localizations.dart';

class HeadAdminHospitalDetailsScreen extends StatelessWidget {
  const HeadAdminHospitalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final col = FirebaseFirestore.instance
        .collection('hospitals')
        .where('status', isEqualTo: 'approved');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.hospitalsOverview,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        backgroundColor: theme.colorScheme.onPrimaryContainer,
        centerTitle: true,
      ),

      backgroundColor: theme.scaffoldBackgroundColor,

      body: StreamBuilder<QuerySnapshot>(
        stream: col.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Text(
                t.noApprovedHospitals,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.hintColor,
                ),
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
                color: theme.colorScheme.primary,
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

    // ❗ احصاء المرضى عبر appointments وليس users
    final appointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('hospitalId', isEqualTo: hospId)
        .get();

    // استخراج المرضى المميزين بدون تكرار
    final patientIds = appointments.docs
        .map((d) => d['patientId'])
        .toSet()
        .length;

    return {
      'doctors': doctors,
      'patients': patientIds,
      'appointments': appointments.size,
    };
  }


  // -------- PDF GENERATOR --------
  Future<void> _generatePdf(
      BuildContext context,
      Map<String, int> data,
      ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Text(
            "$hospName - Hospital Statistics Report",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),

          pw.Text("Doctors: ${data['doctors']}"),
          pw.SizedBox(height: 8),
          pw.Text("Patients: ${data['patients']}"),
          pw.SizedBox(height: 8),
          pw.Text("Appointments: ${data['appointments']}"),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$hospName ${t.hospitalStats}",
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        backgroundColor: theme.colorScheme.onPrimaryContainer,
        centerTitle: true,
      ),

      backgroundColor: theme.scaffoldBackgroundColor,

      body: FutureBuilder<Map<String, int>>(
        future: _load(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
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
              // -------- PDF BUTTON --------
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Download PDF"),
                  onPressed: () async {
                    await _generatePdf(context, data);
                  },
                ),
              ),

              const SizedBox(height: 20),

              _statTile(
                t.doctors,
                data['doctors'] ?? 0,
                Icons.medical_information,
                theme.colorScheme.primary,
              ),

              _statTile(
                t.patients,
                data['patients'] ?? 0,
                Icons.people,
                theme.colorScheme.secondary,
              ),

              _statTile(
                t.appointments,
                data['appointments'] ?? 0,
                Icons.event,
                theme.colorScheme.tertiary,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile(String title, int value, IconData icon, Color color) {
    final textColor =
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          "$value",
          style: TextStyle(color: textColor, fontSize: 20),
        ),
      ),
    );
  }
}
