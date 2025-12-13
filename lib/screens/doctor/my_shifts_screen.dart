import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.todaysAppointments,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
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
            return Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "${t.error} ${snapshot.error}",
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                t.noAppointments,
                style: TextStyle(
                  color: theme.hintColor,
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

              final patientName = (data['patientName'] ?? '-').toString();
              final hospitalName = (data['hospitalName'] ?? '-').toString();
              final ts = data['time'] as Timestamp?;

              final apptDateStr = ts != null ? _formatDate(ts.toDate()) : '—';
              final apptTimeStr = ts != null ? _formatTime(ts.toDate()) : '—';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: Text(
                    patientName,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "${t.date}: $apptDateStr  •  ${t.time}: $apptTimeStr\n${t.hospital}: $hospitalName",
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.onPrimary,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    child: Text(
                      t.addUpdateReport,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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

  // ===================== TIME FORMATTER =====================

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  // ===================== DATE FORMATTER =====================

  String _formatDate(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return "$y-$mo-$d";
  }
}
