import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'add_report.dart';

class MyShiftsScreen extends StatelessWidget {
  final String doctorId;
  const MyShiftsScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Shifts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FS.doctorAppointmentsToday(doctorId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No appointments today"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text("Time: ${data['time'].toDate()}"),
                  subtitle: Text("Patient: ${data['patientName']}"),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddReportScreen(appointmentId: docs[i].id),
                      ));
                    },
                    child: const Text("Add report"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
