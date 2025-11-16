import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchPatient();
    _fetchMedicines();
  }

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

  Future<void> _saveUpdates() async {
    final t = AppLocalizations.of(context)!;

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.medicalRecordUpdated)),
        );
        setState(() {
          _editing = false;
          _medicines.clear();
          _fetchMedicines();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("${t.error} $e")));
    } finally {
      setState(() => _saving = false);
    }
  }

  void _addMedicineRow() {
    setState(() {
      _medicines.add({
        'name': TextEditingController(),
        'dosage': TextEditingController(),
        'days': TextEditingController(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D515C),
        title: Text(
          t.medicalRecord,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _patient == null
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D515C)),
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

  Widget _buildPatientInfo(AppLocalizations t) {
    return Card(
      color: const Color(0xFF2D515C),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSection(AppLocalizations t) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.medicalInfo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D515C),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _chronic,
              readOnly: !_editing,
              decoration: InputDecoration(
                labelText: t.chronicDiseases,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergies,
              readOnly: !_editing,
              decoration: InputDecoration(
                labelText: t.allergies,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesSection(AppLocalizations t) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.medicines,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D515C),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            if (_existingMeds.isEmpty)
              Text(t.noMedicines,
                  style: const TextStyle(color: Colors.black54))
            else
              ..._existingMeds.map((m) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m['name'] ?? '-'),
                subtitle: Text(
                    "${t.medicines}: ${m['dosage'] ?? '-'} • ${t.time}: ${m['days'] ?? '-'}"),
              )),
            if (_editing) ...[
              const SizedBox(height: 10),
              ..._medicines.map((m) => _medicineRow(t, m)).toList(),
              TextButton.icon(
                onPressed: _addMedicineRow,
                icon: const Icon(Icons.add, color: Color(0xFF2D515C)),
                label: Text(
                  t.addMedicine,
                  style: const TextStyle(color: Color(0xFF2D515C)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _medicineRow(AppLocalizations t, Map<String, TextEditingController> med) {
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

  Widget _buildReportsSection(AppLocalizations t) {
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
            style: const TextStyle(color: Colors.black54),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.previousReports,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D515C),
                  fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...docs.map((d) {
              final r = d.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: const Color(0xFF2D515C),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${t.diagnosis}: ${r['diagnosis'] ?? '-'}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${t.notes}: ${r['notes'] ?? '-'}',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('${t.hospital}: ${r['hospitalName'] ?? '-'}',
                          style: const TextStyle(color: Colors.white70)),
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

  Widget _buildUpdateButton(AppLocalizations t) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D515C),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          _editing ? t.saveChanges : t.updateMedicalRecord,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
