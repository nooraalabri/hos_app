import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'patient_drawer.dart';
import 'ui.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';

class SearchPage extends StatefulWidget {
  static const route = '/patient/search';
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final q = TextEditingController();
  late final TabController tabs = TabController(length: 3, vsync: this);

  String? selectedHospital;
  String? selectedSpec;
  String? selectedHospitalId;

  void _filterByHospital(String hospitalName, String hospitalId) {
    setState(() {
      selectedHospital = hospitalName;
      selectedHospitalId = hospitalId;
      selectedSpec = null;
    });
    tabs.animateTo(2);
  }

  void _filterBySpec(String spec) {
    setState(() {
      selectedSpec = spec;
      selectedHospital = null;
      selectedHospitalId = null;
    });
    tabs.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AppScaffold(
      title: t.searchAndBook,
      drawer: const PatientDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: q,
              decoration: input(t.searchHint),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: tabs,
            labelColor: AppColors.dark,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: t.hospitalTab),
              Tab(text: t.specialisationTab),
              Tab(text: t.doctorTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: [
                _HospitalsList(
                  query: q.text,
                  onViewDoctors: _filterByHospital,
                ),
                _SpecialisationsList(
                  query: q.text,
                  onViewDoctors: _filterBySpec,
                ),
                _DoctorsList(
                  query: q.text,
                  hospitalFilterName: selectedHospital,
                  hospitalFilterId: selectedHospitalId,
                  specFilter: selectedSpec,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- HOSPITAL TAB ----------------
class _HospitalsList extends StatelessWidget {
  final String query;
  final void Function(String hospitalName, String hospitalId) onViewDoctors;
  const _HospitalsList({
    required this.query,
    required this.onViewDoctors,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final col = FirebaseFirestore.instance
        .collection('hospitals')
        .where('status', isEqualTo: 'approved')
        .orderBy('name');

    return _SnapList(
      stream: col.snapshots(),
      itemBuilder: (ctx, doc) {
        final d = doc.data();
        final name = d['name'] ?? '';
        final address = d['address'] ?? '';
        final id = doc.id;

        final match = query.isEmpty ||
            name.toLowerCase().contains(query.toLowerCase()) ||
            address.toLowerCase().contains(query.toLowerCase());

        if (!match) return const SizedBox.shrink();

        return _CardTile(
          title: name,
          subtitle:
          '${t.location}: ${address.isEmpty ? t.notSpecified : address}',
          icon: Icons.local_hospital,
          actionText: t.viewDoctors,
          onAction: () => onViewDoctors(name, id),
        );
      },
    );
  }
}

// ---------------- SPECIALISATION TAB ----------------
class _SpecialisationsList extends StatelessWidget {
  final String query;
  final void Function(String spec) onViewDoctors;
  const _SpecialisationsList({
    required this.query,
    required this.onViewDoctors,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final col = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('approved', isEqualTo: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final specs = <String>{};
        for (final d in snap.data!.docs) {
          final s = d['specialization']?.toString() ?? '';
          if (s.toLowerCase().contains(query.toLowerCase())) specs.add(s);
        }

        final list = specs.toList()..sort();
        if (list.isEmpty) return Center(child: Text(t.noResults));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final s = list[i];
            return _CardTile(
              title: s,
              subtitle: t.tapSeeDoctors,
              icon: Icons.medical_information,
              actionText: t.seeDoctors,
              onAction: () => onViewDoctors(s),
            );
          },
        );
      },
    );
  }
}

// ---------------- DOCTOR TAB ----------------
class _DoctorsList extends StatelessWidget {
  final String query;
  final String? hospitalFilterName;
  final String? hospitalFilterId;
  final String? specFilter;
  const _DoctorsList({
    required this.query,
    this.hospitalFilterName,
    this.hospitalFilterId,
    this.specFilter,
  });

  Future<Map<String, String>> _getHospitalInfo(String? hospitalId) async {
    if (hospitalId == null || hospitalId.isEmpty) {
      return {'name': 'Unknown Hospital', 'address': ''};
    }
    final doc = await FirebaseFirestore.instance
        .collection('hospitals')
        .doc(hospitalId)
        .get();
    return {
      'name': doc.data()?['name'] ?? 'Unknown Hospital',
      'address': doc.data()?['address'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final col = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('approved', isEqualTo: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snap.data!.docs;

        final filtered = docs.where((doc) {
          final d = doc.data();
          final name = (d['name'] ?? '').toString().toLowerCase();
          final spec = (d['specialization'] ?? '').toString().toLowerCase();
          final address = (d['address'] ?? '').toString().toLowerCase();
          final hosId = (d['hospitalId'] ?? '').toString();

          if (hospitalFilterId != null && hospitalFilterId!.isNotEmpty) {
            return hosId == hospitalFilterId;
          } else if (specFilter != null && specFilter!.isNotEmpty) {
            return spec.contains(specFilter!.toLowerCase());
          } else if (query.isNotEmpty) {
            final qText = query.toLowerCase();
            return name.contains(qText) ||
                spec.contains(qText) ||
                address.contains(qText);
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              hospitalFilterName != null
                  ? t.noDoctorsForHospital(hospitalFilterName!)
                  : specFilter != null
                  ? t.noDoctorsForSpec(specFilter!)
                  : t.noResults,
              style: const TextStyle(color: AppColors.mid),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final d = filtered[i].data();
            final name = d['name'] ?? '';
            final spec = d['specialization'] ?? '';
            final hosId = d['hospitalId'] ?? '';
            final doctorId = filtered[i].id;
            final address = d['address'] ?? '';

            return FutureBuilder<Map<String, String>>(
              future: _getHospitalInfo(hosId),
              builder: (context, snapshot) {
                final hosName = snapshot.data?['name'] ?? 'Loading...';
                final hosAddress = snapshot.data?['address'] ?? '';
                final location = address.isNotEmpty
                    ? address
                    : (hosAddress.isNotEmpty ? hosAddress : t.notSpecified);

                return _CardTile(
                  title: name,
                  subtitle:
                  '${t.hospital}: $hosName\n${t.specialisation}: ${spec.isEmpty ? t.notSpecified : spec}\n${t.location}: $location',
                  icon: Icons.person,
                  actionText: t.viewShifts,
                  onAction: () => _showShifts(
                    ctx,
                    doctorId,
                    name,
                    hosId,
                    hosName,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showShifts(
      BuildContext ctx,
      String doctorId,
      String doctorName,
      String hospitalId,
      String hospitalName,
      ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _DoctorShiftList(
          doctorId: doctorId,
          doctorName: doctorName,
          hospitalId: hospitalId,
          hospitalName: hospitalName,
        );
      },
    );
  }
}

// ---------------- SHIFT LIST & BOOKING ----------------
class _DoctorShiftList extends StatelessWidget {
  final String doctorId;
  final String doctorName;
  final String hospitalId;
  final String hospitalName;

  const _DoctorShiftList({
    required this.doctorId,
    required this.doctorName,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final todayStart =
    Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final endDate = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day + 30),
    );

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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                t.noShifts,
                style: const TextStyle(color: AppColors.mid),
              ),
            );
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
                    .where(
                  'time',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(date.year, date.month, date.day),
                  ),
                )
                    .where(
                  'time',
                  isLessThan: Timestamp.fromDate(
                    DateTime(date.year, date.month, date.day + 1),
                  ),
                )
                    .get(),
                builder: (ctx, bookedSnap) {
                  if (!bookedSnap.hasData) {
                    return const SizedBox.shrink();
                  }

                  final bookedTimes = bookedSnap.data!.docs.map((doc) {
                    final ts = doc['time'] as Timestamp;
                    final dt = ts.toDate();
                    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  }).toSet();

                  final availableSlots = _generateHourlySlots(start, end)
                      .where((slot) {
                    final parts = slot.split(':').map(int.parse).toList();
                    final slotTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      parts[0],
                      parts[1],
                    );
                    return slotTime.isAfter(DateTime.now()) &&
                        !bookedTimes.contains(slot);
                  }).toList();

                  return ExpansionTile(
                    title: Text(
                      'Date: ${_fmtDate(date)}',
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      t.slotsAvailable(availableSlots.length.toString()),
                      style: const TextStyle(color: AppColors.mid),
                    ),
                    children: availableSlots.map((slot) {
                      return ListTile(
                        title: Text(
                          '${t.time}: $slot',
                          style: const TextStyle(color: AppColors.dark),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                          onPressed: () => _confirmBook(
                            ctx,
                            slot,
                            doctorId,
                            doctorName,
                            hospitalId,
                            hospitalName,
                            date,
                            d.id,
                          ),
                          child: Text(t.confirm),
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
    final sParts = start.split(':').map(int.parse).toList();
    final eParts = end.split(':').map(int.parse).toList();
    final sTime = DateTime(2024, 1, 1, sParts[0], sParts[1]);
    final eTime = DateTime(2024, 1, 1, eParts[0], eParts[1]);
    final diff = eTime.difference(sTime).inHours;

    return List.generate(diff, (i) {
      final t = sTime.add(Duration(hours: i));
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    });
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _confirmBook(
      BuildContext ctx,
      String slot,
      String doctorId,
      String doctorName,
      String hospitalId,
      String hospitalName,
      DateTime date,
      String shiftId,
      ) async {
    final t = AppLocalizations.of(ctx)!;

    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: Text(t.confirmBooking),
        content: Text(
          t.confirmBookingQuestion(
            doctorName,
            _fmtDate(date),
            slot,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.confirm),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _book(
        ctx,
        slot,
        doctorId,
        doctorName,
        hospitalId,
        hospitalName,
        date,
        shiftId,
      );
    }
  }

  Future<void> _book(
      BuildContext ctx,
      String slot,
      String doctorId,
      String doctorName,
      String hospitalId,
      String hospitalName,
      DateTime date,
      String shiftId,
      ) async {
    final t = AppLocalizations.of(ctx)!;

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final fs = FirebaseFirestore.instance;

      final patientDoc = await fs.collection('users').doc(uid).get();
      final patientName = patientDoc.data()?['name'] ?? 'Unknown';

      final slotParts = slot.split(':').map(int.parse).toList();
      final dt = DateTime(
        date.year,
        date.month,
        date.day,
        slotParts[0],
        slotParts[1],
      );
      final ts = Timestamp.fromDate(dt);

      final startOfDay =
      Timestamp.fromDate(DateTime(date.year, date.month, date.day));
      final endOfDay =
      Timestamp.fromDate(DateTime(date.year, date.month, date.day + 1));

      final sameDayExisting = await fs
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: uid)
          .where('time', isGreaterThanOrEqualTo: startOfDay)
          .where('time', isLessThan: endOfDay)
          .get();

      if (sameDayExisting.docs.isNotEmpty) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(t.alreadyBookedToday(doctorName))),
        );
        return;
      }

      final existing = await fs
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('time', isEqualTo: ts)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(t.slotBooked)),
        );
        return;
      }

      final apptData = {
        'patientId': uid,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'shiftId': shiftId,
        'time': ts,
        'status': 'booked',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final rootRef = await fs.collection('appointments').add(apptData);

      await fs
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .doc(rootRef.id)
          .set(apptData);

      // Get formatted date for notifications
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Send notification and email to patient via notification server
      await NotificationService.sendFCMNotification(
        userId: uid,
        title: 'Appointment Booked Successfully',
        body: 'Your appointment with Dr. $doctorName on $formattedDate at $slot has been confirmed.',
        data: {
          'type': 'appointment_booked',
          'appointmentId': rootRef.id,
          'doctorName': doctorName,
          'hospitalName': hospitalName,
        },
      );

      // Also store in notifications collection for UI
      await fs.collection('notifications').add({
        'userId': uid,
        'toRole': 'patient',
        'title': 'Appointment Booked Successfully',
        'body': 'Your appointment with Dr. $doctorName on $formattedDate at $slot has been confirmed.',
        'appointmentId': rootRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send notification and email to doctor via notification server
      await NotificationService.sendFCMNotification(
        userId: doctorId,
        title: 'New Appointment Booking',
        body: 'Patient $patientName has booked an appointment on $formattedDate at $slot.',
        data: {
          'type': 'new_appointment',
          'appointmentId': rootRef.id,
          'patientName': patientName,
          'hospitalName': hospitalName,
        },
      );

      // Store notification for doctor
      await fs.collection('notifications').add({
        'userId': doctorId,
        'toRole': 'doctor',
        'title': 'New Appointment Booking',
        'body': 'Patient $patientName has booked an appointment on $formattedDate at $slot.',
        'appointmentId': rootRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(t.appointmentBooked(slot, doctorName)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(t.errorBooking(e.toString()))),
      );
    }
  }
}

// ---------------- HELPERS ----------------
class _SnapList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Widget Function(
      BuildContext,
      QueryDocumentSnapshot<Map<String, dynamic>>,
      ) itemBuilder;

  const _SnapList({
    required this.stream,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) return Center(child: Text(t.noResults));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => itemBuilder(ctx, docs[i]),
        );
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  final String title, subtitle, actionText;
  final IconData icon;
  final VoidCallback onAction;

  const _CardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.dark,   // ← لون الأيقونة واضح
            size: 42,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              '$title\n$subtitle',
              style: const TextStyle(
                color: AppColors.dark,   // ← النص واضح
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 12),

          PrimaryButton(
            text: actionText,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
