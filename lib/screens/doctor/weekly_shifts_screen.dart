import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ShiftsOverviewScreen extends StatelessWidget {
  final String doctorId;
  const ShiftsOverviewScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F2F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D515C),
          title: const Text(
            "My Shifts",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Daily"),
              Tab(text: "Weekly"),
              Tab(text: "Monthly"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildShiftList(doctorId, 'daily'),
            _buildShiftList(doctorId, 'weekly'),
            _buildShiftList(doctorId, 'monthly'),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftList(String doctorId, String type) {
    late final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
    if (type == 'daily') {
      stream = FS.doctorShiftsDaily(doctorId);
    } else if (type == 'weekly') {
      stream = FS.doctorShiftsWeekly(doctorId);
    } else {
      stream = FS.doctorShiftsMonthly(doctorId);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2D515C)),
          );
        }

        if (snapshot.hasError) {
          return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No shifts found",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          );
        }

        final shifts = docs.map((d) {
          final data = d.data();
          final raw = data['dateTs'];
          Timestamp? ts;
          if (raw is Timestamp) ts = raw;
          else if (raw is String) {
            final parsed = DateTime.tryParse(raw);
            if (parsed != null) ts = Timestamp.fromDate(parsed);
          }
          return {
            'id': d.id,
            'date': data['date'] ?? '',
            'day': data['day'] ?? '',
            'startTime': data['startTime'] ?? '',
            'endTime': data['endTime'] ?? '',
            'dateTs': ts,
          };
        }).where((e) => e['dateTs'] != null).toList();

        shifts.sort((a, b) {
          final ad = (a['dateTs'] as Timestamp).toDate();
          final bd = (b['dateTs'] as Timestamp).toDate();
          return ad.compareTo(bd);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shifts.length,
          itemBuilder: (context, i) {
            final s = shifts[i];
            final shiftId = s['id']; // 🟢 لازم كل appointment فيها shiftId
            final date = s['date'];
            final day = s['day'];
            final start = s['startTime'];
            final end = s['endTime'];

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              color: const Color(0xFF2D515C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
              child: ExpansionTile(
                collapsedIconColor: Colors.white,
                iconColor: Colors.white,
                title: Text(
                  "$day • $date",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  "Time: $start - $end",
                  style: const TextStyle(color: Colors.white70),
                ),
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      // ✅ تم التعديل هنا: نحصر البحث في المجموعة الرئيسية فقط
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('doctorId', isEqualTo: doctorId)
                          .where('shiftId', isEqualTo: shiftId)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final appts = snap.data?.docs ?? [];
                        if (appts.isEmpty) {
                          return const Text(
                            "No appointments in this shift",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          );
                        }

                        return Column(
                          children: appts.map((a) {
                            final m = a.data();
                            final name = m['patientName'] ?? 'Unknown';
                            final status = m['status'] ?? 'pending';
                            final rawTime = m['time'];
                            String time = '';

                            if (rawTime is Timestamp) {
                              final dt = rawTime.toDate().toLocal();
                              time =
                              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                            } else if (rawTime is String) {
                              time = rawTime;
                            }

                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F2F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.schedule,
                                    color: Color(0xFF2D515C)),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D515C)),
                                ),
                                subtitle: Text(
                                  "Time: $time\nStatus: $status",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
