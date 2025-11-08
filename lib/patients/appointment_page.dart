import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'patient_drawer.dart';
import 'ui.dart';

class AppointmentPage extends StatelessWidget {
  static const route = '/patient/appointments';
  const AppointmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .orderBy('time', descending: true);

    return AppScaffold(
      title: 'My appointments',
      drawer: const PatientDrawer(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2D515C)));
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No appointments yet',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final d = docs[i].data();
              final docRef = docs[i].reference;

              final dtRaw = d['time'];
              final dt = dtRaw is Timestamp
                  ? dtRaw.toDate()
                  : DateTime.tryParse(dtRaw.toString());
              final formattedDate = dt != null
                  ? DateFormat('yyyy-MM-dd • hh:mm a').format(dt)
                  : 'Unknown';

              final status = (d['status'] ?? 'booked').toString();
              Color statusColor;
              switch (status) {
                case 'confirmed':
                  statusColor = Colors.teal.shade700;
                  break;
                case 'cancelled':
                  statusColor = Colors.red.shade700;
                  break;
                case 'completed':
                  statusColor = Colors.green.shade700;
                  break;
                default:
                  statusColor = Colors.grey.shade700;
              }

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D515C),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['hospitalName'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Doctor: ${d['doctorName'] ?? ''}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Time: $formattedDate',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Status: $status',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    //  الأزرار
                    if (status == 'booked' || status == 'confirmed')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel button
                          TextButton.icon(
                            onPressed: () async {
                              await docRef.update({'status': 'cancelled'});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Appointment cancelled'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            },
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            label: const Text('Cancel',
                                style: TextStyle(color: Colors.redAccent)),
                          ),
                          const SizedBox(width: 8),

                          // Reschedule button
                          TextButton.icon(
                            onPressed: () {
                              _showAvailableSlots(
                                context,
                                d['doctorId'],
                                d['doctorName'],
                                d['hospitalName'],
                                docRef,
                              );
                            },
                            icon: const Icon(Icons.edit_calendar, color: Colors.white70),
                            label: const Text('Reschedule',
                                style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  //  نفس نظام السيرش
  void _showAvailableSlots(BuildContext ctx, String doctorId, String doctorName,
      String hospitalName, DocumentReference<Map<String, dynamic>> oldRef) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _RescheduleShiftList(
          doctorId: doctorId,
          doctorName: doctorName,
          hospitalName: hospitalName,
          oldRef: oldRef,
        );
      },
    );
  }
}

// Widget جديد لعرض الشفتات المتاحة فقط (بدون الأوقات المنتهية)
class _RescheduleShiftList extends StatelessWidget {
  final String doctorId;
  final String doctorName;
  final String hospitalName;
  final DocumentReference<Map<String, dynamic>> oldRef;

  const _RescheduleShiftList({
    required this.doctorId,
    required this.doctorName,
    required this.hospitalName,
    required this.oldRef,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final endDate = Timestamp.fromDate(DateTime(now.year, now.month, now.day + 30));

    final col = FirebaseFirestore.instance
        .collectionGroup('shifts')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTs', isGreaterThanOrEqualTo: todayStart)
        .where('dateTs', isLessThan: endDate)
        .orderBy('dateTs');

    return Container(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col.snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No available shifts'));
          }

          return ListView(
            children: docs.map((d) {
              final s = d.data();
              final date = (s['dateTs'] as Timestamp).toDate();
              final start = s['startTime'] ?? '00:00';
              final end = s['endTime'] ?? '00:00';

              return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('doctorId', isEqualTo: doctorId)
                    .where('time', isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
                    .where('time', isLessThan:
                Timestamp.fromDate(DateTime(date.year, date.month, date.day + 1)))
                    .get(),
                builder: (ctx, bookedSnap) {
                  if (!bookedSnap.hasData) return const SizedBox.shrink();

                  final bookedTimes = bookedSnap.data!.docs.map((doc) {
                    final ts = doc['time'] as Timestamp;
                    final dt = ts.toDate();
                    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  }).toSet();

                  final availableSlots = _generateHourlySlots(start, end)
                      .where((slot) {
                    final slotParts = slot.split(':').map(int.parse).toList();
                    final slotTime = DateTime(
                        date.year, date.month, date.day, slotParts[0], slotParts[1]);
                    return slotTime.isAfter(DateTime.now()) &&
                        !bookedTimes.contains(slot);
                  })
                      .toList();

                  return ExpansionTile(
                    title: Text('Date: ${DateFormat('yyyy-MM-dd').format(date)}'),
                    subtitle: Text('${availableSlots.length} slots available'),
                    children: availableSlots.map((slot) {
                      return ListTile(
                        title: Text('Time: $slot'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final slotParts = slot.split(':').map(int.parse).toList();
                            final newDate = DateTime(
                                date.year, date.month, date.day, slotParts[0], slotParts[1]);

                            await oldRef.update({
                              'time': Timestamp.fromDate(newDate),
                              'status': 'booked',
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Appointment rescheduled to $slot on ${DateFormat('yyyy-MM-dd').format(date)}'),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            }
                          },
                          child: const Text('Select'),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  static List<String> _generateHourlySlots(String start, String end) {
    try {
      final sParts = start.split(':').map(int.parse).toList();
      final eParts = end.split(':').map(int.parse).toList();
      final sTime = DateTime(2024, 1, 1, sParts[0], sParts[1]);
      final eTime = DateTime(2024, 1, 1, eParts[0], eParts[1]);
      final diff = eTime.difference(sTime).inHours;
      return List.generate(diff, (i) {
        final t = sTime.add(Duration(hours: i));
        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      });
    } catch (_) {
      return [];
    }
  }
}
