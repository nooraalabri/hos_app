import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medical_records.dart';
import 'report_details.dart';
import 'package:hos_app/l10n/app_localizations.dart';

class AddReport extends StatefulWidget {
  final String appointmentId;
  final String patientId;
  final String doctorId;

  const AddReport({
    super.key,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
  });

  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  final _form = GlobalKey<FormState>();
  final _general = TextEditingController();
  final _chronic = TextEditingController();
  final _allergies = TextEditingController();
  bool _saving = false;

  final List<Map<String, TextEditingController>> _medicines = [];
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _addMedicineRow();
    _loadExistingReport();
  }

  Future<void> _loadExistingReport() async {
    final snap = await _db
        .collection('reports')
        .where('appointmentId', isEqualTo: widget.appointmentId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      _general.text = data['report'] ?? '';
      _chronic.text = (data['chronic'] ?? []).join(', ');
      _allergies.text = data['allergies'] ?? '';
    }
  }

  void _addMedicineRow() {
    setState(() {
      _medicines.add({
        'name': TextEditingController(),
        'dosage': TextEditingController(),
        'days': TextEditingController(),
        'notes': TextEditingController(),
      });
    });
  }

  void _removeMedicineRow(int index) {
    setState(() => _medicines.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D515C),
        title: Text(
          t.reportAddUpdate,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(t.generalReport,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _general,
              maxLines: 3,
              decoration: _input(t.generalReportHint),
              validator: (v) =>
              v == null || v.isEmpty ? t.generalReportRequired : null,
            ),
            const SizedBox(height: 20),

            Text(t.patientMedicalInfo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _chronic,
              decoration: _input(t.chronicHint),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _allergies,
              decoration: _input(t.allergyHint),
            ),
            const SizedBox(height: 20),

            Text(t.medicineSection,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _medicineTable(t),
            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D515C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saving ? null : _submitReport,
              child: _saving
                  ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : Text(t.saveReport,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            const SizedBox(height: 30),

            Text(t.previousReports,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            _previousReports(t),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    final t = AppLocalizations.of(context)!;

    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final reportsRef = _db.collection('reports');
      final existing = await reportsRef
          .where('appointmentId', isEqualTo: widget.appointmentId)
          .limit(1)
          .get();

      final meds = _medicines
          .where((m) => m['name']!.text.isNotEmpty)
          .map((m) => {
        'name': m['name']!.text.trim(),
        'dosage': m['dosage']!.text.trim(),
        'days': m['days']!.text.trim(),
        'notes': m['notes']!.text.trim(),
      })
          .toList();

      if (existing.docs.isNotEmpty) {
        await reportsRef.doc(existing.docs.first.id).update({
          'report': _general.text.trim(),
          'chronic': _chronic.text.trim().isNotEmpty
              ? _chronic.text.split(',').map((e) => e.trim()).toList()
              : [],
          'allergies': _allergies.text.trim(),
          'medicationsList': meds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await reportsRef.add({
          'appointmentId': widget.appointmentId,
          'patientId': widget.patientId,
          'doctorId': widget.doctorId,
          'report': _general.text.trim(),
          'chronic': _chronic.text.trim().isNotEmpty
              ? _chronic.text.split(',').map((e) => e.trim()).toList()
              : [],
          'allergies': _allergies.text.trim(),
          'medicationsList': meds,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.saveReportSuccess)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MedicalRecord(
            patientId: widget.patientId,
            appointmentId: widget.appointmentId,
            doctorId: widget.doctorId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${t.errorPrefix} $e")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  Widget _medicineTable(AppLocalizations t) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(0.6),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF2D515C)),
                children: [
                  _TableHeader(t.medicineName),
                  _TableHeader(t.medicineDosage),
                  _TableHeader(t.medicineDays),
                  _TableHeader(t.medicineNotes),
                  const _TableHeader(""),
                ],
              ),
              ..._medicines.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                return TableRow(children: [
                  _TableCell(TextFormField(
                      controller: med['name'],
                      decoration: _miniInput(t.medicineNameHint,
                          color: Colors.grey[200]!),
                      validator: (v) =>
                      v == null || v.isEmpty ? t.requiredField : null)),
                  _TableCell(TextFormField(
                      controller: med['dosage'],
                      decoration: _miniInput(t.medicineDosageHint))),
                  _TableCell(TextFormField(
                      controller: med['days'],
                      keyboardType: TextInputType.number,
                      decoration: _miniInput(t.medicineDaysHint))),
                  _TableCell(TextFormField(
                      controller: med['notes'],
                      decoration: _miniInput(t.medicineNotesHint))),
                  _TableCell(IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeMedicineRow(i))),
                ]);
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _addMedicineRow,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2D515C)),
            label: Text(
              t.addMedicine,
              style: const TextStyle(color: Color(0xFF2D515C)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previousReports(AppLocalizations t) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('reports')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.docs.isEmpty) {
          return Text(t.noReports);
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final ts = d['createdAt'] as Timestamp?;
            final date = ts != null
                ? "${ts.toDate().year}-${ts.toDate().month}-${ts.toDate().day}"
                : '—';
            return Card(
              child: ListTile(
                title: Text(d['report'] ?? t.noDetails),
                subtitle: Text("${t.dateLabel}: $date"),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Color(0xFF2D515C)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ReportDetails(reportData: d, reportId: doc.id)),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2D515C))),
  );

  static InputDecoration _miniInput(String hint, {Color color = Colors.white}) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: color,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        border: InputBorder.none,
      );
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(6),
    child: Center(
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13))),
  );
}

class _TableCell extends StatelessWidget {
  final Widget child;
  const _TableCell(this.child);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(4), child: child);
}
