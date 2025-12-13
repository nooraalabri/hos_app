import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../l10n/app_localizations.dart';

class ShiftsOverviewScreen extends StatelessWidget {
  final String doctorId;
  const ShiftsOverviewScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          title: Text(
            t.myShifts,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
            tabs: [
              Tab(text: t.daily),
              Tab(text: t.weekly),
              Tab(text: t.monthly),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildShiftList(context, doctorId, 'daily'),
            _buildShiftList(context, doctorId, 'weekly'),
            _buildShiftList(context, doctorId, 'monthly'),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftList(BuildContext context, String doctorId, String type) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
          return Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text("${t.error} ${snapshot.error}"));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              t.noShifts,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.hintColor,
              ),
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
            final shiftId = s['id'];
            final date = s['date'];
            final day = s['day'];
            final start = s['startTime'];
            final end = s['endTime'];

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              color: theme.colorScheme.primary,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ExpansionTile(
                collapsedIconColor: theme.colorScheme.onPrimary,
                iconColor: theme.colorScheme.onPrimary,
                title: Text(
                  "$day • $date",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                subtitle: Text(
                  "${t.timeLabel}: $start - $end",
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
                children: [
                  Container(
                    color: theme.cardColor,
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                          return Center(
                            child: Text(
                              t.noAppointmentsInShift,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: theme.hintColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return Column(
                          children: appts.map((a) {
                            final m = a.data();
                            final name = m['patientName'] ?? '—';
                            final status = m['status'] ?? '—';

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
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.schedule,
                                  color: theme.colorScheme.primary,
                                ),
                                title: Text(
                                  name,
                                  style: theme.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                subtitle: Text(
                                  "${t.timeLabel}: $time\n${t.statusLabel}: $status",
                                  style: theme.textTheme.bodyMedium,
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
