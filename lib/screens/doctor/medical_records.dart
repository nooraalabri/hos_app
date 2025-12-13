import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../l10n/app_localizations.dart';

class MedicalRecord extends StatefulWidget {
  final String patientId;
  final String appointmentId;
  final String doctorId;

  const MedicalRecord({
    super.key,
    required this.patientId,
    required this.appointmentId,
    required this.doctorId,
  });

  @override
  State<MedicalRecord> createState() => _MedicalRecordState();
}

class _MedicalRecordState extends State<MedicalRecord> {
  final _db = FirebaseFirestore.instance;
  bool _editing = false;
  bool _saving = false;

  final _chronic = TextEditingController();
  final _allergies = TextEditingController();
  final List<Map<String, TextEditingController>> _medicines = [];

  Map<String, dynamic>? _patient;
  List<Map<String, dynamic>> _existingMeds = [];
  List<Map<String, dynamic>> _reportsPdfCache = [];

  @override
  void initState() {
    super.initState();
    _fetchPatient();
    _fetchMedicines();
    _fetchReportsForPdf();
  }

  // ----------------------- FETCH PATIENT -----------------------
  Future<void> _fetchPatient() async {
    final doc = await _db.collection('users').doc(widget.patientId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      _patient = data;
      _chronic.text = (data['chronic'] ?? []).join(', ');
      _allergies.text = data['allergies'] ?? '';
    });
  }

  // ----------------------- FETCH MEDICINES -----------------------
  Future<void> _fetchMedicines() async {
    final meds = await _db
        .collection('users')
        .doc(widget.patientId)
        .collection('medicines')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _existingMeds = meds.docs.map((d) => d.data()).toList();
    });
  }

  // ----------------------- FETCH REPORTS FOR PDF -----------------------
  Future<void> _fetchReportsForPdf() async {
    final reports = await _db
        .collection('users')
        .doc(widget.patientId)
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _reportsPdfCache = reports.docs.map((r) => r.data()).toList();
    });
  }

  // ----------------------- SAVE UPDATES -----------------------
  Future<void> _saveUpdates() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    setState(() => _saving = true);
    try {
      await _db.collection('users').doc(widget.patientId).set({
        'chronic': _chronic.text.trim().isNotEmpty
            ? _chronic.text.split(',').map((e) => e.trim()).toList()
            : [],
        'allergies': _allergies.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      for (final med in _medicines) {
        final name = med['name']!.text.trim();
        if (name.isEmpty) continue;

        await _db
            .collection('users')
            .doc(widget.patientId)
            .collection('medicines')
            .add({
          'name': name,
          'dosage': med['dosage']!.text.trim(),
          'days': med['days']!.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.medicalRecordUpdated),
          backgroundColor: theme.colorScheme.primary,
        ),
      );

      setState(() {
        _editing = false;
        _medicines.clear();
      });

      _fetchMedicines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("${t.error} $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _addMedicineRow() {
    _medicines.add({
      'name': TextEditingController(),
      'dosage': TextEditingController(),
      'days': TextEditingController(),
    });
    setState(() {});
  }

  // ----------------------- PDF GENERATOR -----------------------
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    final patient = _patient ?? {};
    final chronic = (patient['chronic'] ?? []).join(', ');
    final allergies = patient['allergies'] ?? '';

    final name = patient['name'] ?? '-';
    final phone = patient['phone'] ?? '-';
    final blood = patient['bloodType'] ?? '-';
    final dob = patient['dob'] ?? '-';

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "MEDICAL RECORD REPORT",
              style:
              pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          // -------------------- PATIENT INFO --------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Patient Information",
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text("Name: $name"),
                pw.Text("Date of Birth: $dob"),
                pw.Text("Phone: $phone"),
                pw.Text("Blood Type: $blood"),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // -------------------- MEDICAL INFO --------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Medical Information",
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text("Chronic Diseases: $chronic"),
                pw.Text("Allergies: $allergies"),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // -------------------- MEDICINES TABLE --------------------
          pw.Text("Current Medicines",
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),

          _existingMeds.isEmpty
              ? pw.Text("No medicines recorded.")
              : pw.Table.fromTextArray(
            headers: ["Medicine", "Dosage", "Days"],
            data: _existingMeds
                .map((m) => [
              m['name'] ?? '-',
              m['dosage'] ?? '-',
              m['days'] ?? '-'
            ])
                .toList(),
          ),

          pw.SizedBox(height: 25),

          // -------------------- REPORTS TABLE --------------------
          pw.Text("Previous Reports",
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),

          _reportsPdfCache.isEmpty
              ? pw.Text("No previous reports.")
              : pw.Table.fromTextArray(
            headers: ["Diagnosis", "Notes", "Hospital"],
            data: _reportsPdfCache
                .map((r) => [
              r['diagnosis'] ?? '-',
              r['notes'] ?? '-',
              r['hospitalName'] ?? '-',
            ])
                .toList(),
          ),

          pw.SizedBox(height: 40),

          pw.Text("Doctor Signature: __________________________"),
          pw.SizedBox(height: 10),
          pw.Text("Hospital Stamp: ____________________________"),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // ----------------------- UI -----------------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.medicalRecord,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
          ),
        ],
      ),

      body: _patient == null
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPatientInfo(t),
          const SizedBox(height: 16),
          _buildMedicalSection(t),
          const SizedBox(height: 16),
          _buildMedicinesSection(t),
          const SizedBox(height: 16),
          _buildReportsSection(t),
          const SizedBox(height: 30),
          _buildUpdateButton(t),
        ],
      ),
    );
  }

  // ----------------------- PATIENT INFO CARD -----------------------
  Widget _buildPatientInfo(AppLocalizations t) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(t.name, _patient?['name'] ?? '-'),
            _infoRow(t.dob, _patient?['dob'] ?? '-'),
            _infoRow(t.phone, _patient?['phone'] ?? '-'),
            _infoRow(t.bloodType, _patient?['bloodType'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------- MEDICAL INFO CARD -----------------------
  Widget _buildMedicalSection(AppLocalizations t) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.medicalInfo,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // chronic
            TextFormField(
              controller: _chronic,
              readOnly: !_editing,
              decoration: InputDecoration(
                labelText: t.chronicDiseases,
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // allergies
            TextFormField(
              controller: _allergies,
              readOnly: !_editing,
              decoration: InputDecoration(
                labelText: t.allergies,
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------- MEDICINES SECTION -----------------------
  Widget _buildMedicinesSection(AppLocalizations t) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.medicines,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 10),

            if (_existingMeds.isEmpty)
              Text(
                t.noMedicines,
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: theme.hintColor),
              )
            else
              ..._existingMeds.map(
                    (m) => ListTile(
                  title: Text(m['name'] ?? '-'),
                  subtitle: Text(
                    "${t.medicines}: ${m['dosage'] ?? '-'} • ${t.time}: ${m['days'] ?? '-'}",
                  ),
                ),
              ),

            if (_editing) ...[
              const SizedBox(height: 10),
              ..._medicines.map((m) => _medicineRow(t, m)),
              TextButton.icon(
                onPressed: _addMedicineRow,
                icon: Icon(Icons.add, color: theme.colorScheme.primary),
                label: Text(
                  t.addMedicine,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _medicineRow(
      AppLocalizations t, Map<String, TextEditingController> med) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: med['name'],
              decoration: InputDecoration(labelText: t.name),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: med['dosage'],
              decoration: InputDecoration(labelText: t.time),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: med['days'],
              decoration: InputDecoration(labelText: t.date),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------- REPORTS SECTION -----------------------
  Widget _buildReportsSection(AppLocalizations t) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(widget.patientId)
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return Text(
            t.noPreviousReports,
            style:
            theme.textTheme.bodyMedium!.copyWith(color: theme.hintColor),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.previousReports,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            ...docs.map((d) {
              final r = d.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.diagnosis}: ${r['diagnosis'] ?? '-'}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.notes}: ${r['notes'] ?? '-'}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary
                              .withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.hospital}: ${r['hospitalName'] ?? '-'}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary
                              .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ----------------------- SAVE BUTTON -----------------------
  Widget _buildUpdateButton(AppLocalizations t) {
    final theme = Theme.of(context);

    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _saving
            ? null
            : () {
          if (_editing) {
            _saveUpdates();
          } else {
            setState(() => _editing = true);
          }
        },
        child: _saving
            ? SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onPrimary,
          ),
        )
            : Text(
          _editing ? t.saveChanges : t.updateMedicalRecord,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
