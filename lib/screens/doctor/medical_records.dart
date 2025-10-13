import 'package:flutter/material.dart';

class MedicalRecordsScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  const MedicalRecordsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medical Records")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Medical Record: ${record['report'] ?? '---'}"),
            const SizedBox(height: 16),
            Text("Medicines: ${record['medicines'] ?? '---'}"),
          ],
        ),
      ),
    );
  }
}
