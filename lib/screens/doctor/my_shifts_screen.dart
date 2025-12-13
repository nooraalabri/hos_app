import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_report_screen.dart';

class MyShiftsScreen extends StatefulWidget {
  final String doctorId;
  const MyShiftsScreen({super.key, required this.doctorId});

  @override
  State<MyShiftsScreen> createState() => _MyShiftsScreenState();
}

class _MyShiftsScreenState extends State<MyShiftsScreen> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D515C),
        title: const Text(
          "Today's Appointments",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('appointments')
            .where('doctorId', isEqualTo: widget.doctorId)
            .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('time', isLessThan: Timestamp.fromDate(endOfDay))
            .orderBy('time', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D515C)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No appointments for today",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final appts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appts.length,
            itemBuilder: (context, i) {
              final data = appts[i].data() as Map<String, dynamic>;
              final apptId = appts[i].id;
              final patientName = (data['patientName'] ?? 'Unknown').toString();
              final hospitalName = (data['hospitalName'] ?? '').toString();
              final ts = data['time'] as Timestamp?;
              final apptDateStr = ts != null ? _formatDate(ts.toDate()) : '—';
              final apptTimeStr = ts != null ? _formatTime(ts.toDate()) : '—';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D515C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: Text(
                    patientName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  subtitle: Text(
                    "Date: $apptDateStr  •  Time: $apptTimeStr\nHospital: $hospitalName",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D515C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddReport(
                            appointmentId: apptId,
                            patientId: data['patientId'],
                            doctorId: widget.doctorId,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Add / Update Report",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ======== تنسيق الوقت ========
  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  // ======== تنسيق التاريخ ========
  String _formatDate(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return "$y-$mo-$d";
  }
}
