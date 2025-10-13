import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class AddReportScreen extends StatefulWidget {
  final String appointmentId;
  const AddReportScreen({super.key, required this.appointmentId});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _report = TextEditingController();
  final _medicines = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _report,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Medical Record", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _medicines,
              decoration: const InputDecoration(labelText: "Medicines", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                setState(() => _saving = true);
                await FS.addMedicalReport(widget.appointmentId, _report.text.trim(), _medicines.text.trim()); // ✅
                if (mounted) Navigator.pop(context);
              },
              child: _saving ? const CircularProgressIndicator() : const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
