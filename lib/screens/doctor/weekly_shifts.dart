import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class WeeklyShiftsScreen extends StatelessWidget {
  final String doctorId;
  const WeeklyShiftsScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Shifts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FS.doctorAppointmentsWeekly(doctorId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text("Day: ${data['time'].toDate().weekday}"),
                  subtitle: Text("Appointments: ${data['patientName']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
