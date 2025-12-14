import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import 'patient_drawer.dart';
import 'ui.dart';

class SearchPage extends StatefulWidget {
  static const route = '/patient/search';
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
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
    return AppScaffold(
      title: AppLocalizations.of(context)!.search_book,
      drawer: const PatientDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: q,
              decoration: input('Search by hospital, specialization, doctor, or location...'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: tabs,
            labelColor: AppColors.dark,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.hospital),
              Tab(text: AppLocalizations.of(context)!.specialisation),
              Tab(text: AppLocalizations.of(context)!.doctor),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: [
                _HospitalsList(query: q.text, onViewDoctors: _filterByHospital),
                _SpecialisationsList(query: q.text, onViewDoctors: _filterBySpec),
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
  const _HospitalsList({required this.query, required this.onViewDoctors});

  @override
  Widget build(BuildContext context) {
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
          subtitle: 'Location: ${address.isEmpty ? 'Not specified' : address}',
          icon: Icons.local_hospital,
          actionText: AppLocalizations.of(context)!.view_doctors,
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
  const _SpecialisationsList({required this.query, required this.onViewDoctors});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('approved', isEqualTo: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final specs = <String>{};
        for (final d in snap.data!.docs) {
          final s = d['specialization']?.toString() ?? '';
          if (s.toLowerCase().contains(query.toLowerCase())) specs.add(s);
        }
        final list = specs.toList()..sort();
        if (list.isEmpty) return const Center(child: Text('No results'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final s = list[i];
            return _CardTile(
              title: s,
              subtitle: AppLocalizations.of(context)!.tap_see_doctors,
              icon: Icons.medical_information,
              actionText: AppLocalizations.of(context)!.see_doctors,
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
  const _DoctorsList({required this.query, this.hospitalFilterName, this.hospitalFilterId, this.specFilter});

  Future<Map<String, String>> _getHospitalInfo(String? hospitalId) async {
    if (hospitalId == null || hospitalId.isEmpty) return {'name': 'Unknown Hospital', 'address': ''};
    final doc = await FirebaseFirestore.instance.collection('hospitals').doc(hospitalId).get();
    return {
      'name': doc.data()?['name'] ?? 'Unknown Hospital',
      'address': doc.data()?['address'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('approved', isEqualTo: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
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
            return name.contains(qText) || spec.contains(qText) || address.contains(qText);
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
            final loc = AppLocalizations.of(context);
            return Center(
              child: Text(
                hospitalFilterName != null
                    ? loc!.no_doctors_found(hospitalFilterName!)
                    : specFilter != null
                    ? loc!.no_doctors_found_spec(specFilter!)
                    : loc!.no_results_found,
                style: const TextStyle(color: Colors.grey),
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
                final loc = AppLocalizations.of(context);
                final hosName = snapshot.data?['name'] ?? 'Loading...';
                final hosAddress = snapshot.data?['address'] ?? '';
                final location = address.isNotEmpty ? address : (hosAddress.isNotEmpty ? hosAddress : 'Not specified');

                return _CardTile(
                  title: name,
              subtitle:
                  '${loc!.hospital}: $hosName\n${loc.specialisation}: ${spec.isEmpty ? loc.specialisation_not_specified('') : spec}\n${loc.location}: $location',
              icon: Icons.person,
              actionText: loc.view_shifts,
                  onAction: () => _showShifts(ctx, doctorId, name, hosName),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showShifts(BuildContext ctx, String doctorId, String doctorName, String hospitalName) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _DoctorShiftList(
          doctorId: doctorId,
          doctorName: doctorName,
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
  final String hospitalName;
  const _DoctorShiftList({
    required this.doctorId,
    required this.doctorName,
    required this.hospitalName,
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
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col.snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            final loc = AppLocalizations.of(context);
            return Center(
              child: Text(loc!.no_available_shifts, style: const TextStyle(color: Colors.black87)),
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
                    .where('time', isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
                    .where('time', isLessThan:
                Timestamp.fromDate(DateTime(date.year, date.month, date.day + 1)))
                    .get(),
                builder: (ctx, bookedSnap) {
                  if (!bookedSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookedTimes = bookedSnap.data!.docs.map((doc) {
                    final ts = doc['time'] as Timestamp;
                    final dt = ts.toDate();
                    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  }).toSet();

                  var availableSlots = _generateHourlySlots(start, end)
                      .where((slot) => !bookedTimes.contains(slot))
                      .toList();

                  //  إخفاء الأوقات المنتهية لليوم الحالي
                  final now = DateTime.now();
                  if (date.year == now.year && date.month == now.month && date.day == now.day) {
                    availableSlots = availableSlots.where((slot) {
                      final parts = slot.split(':').map(int.parse).toList();
                      final slotTime = DateTime(now.year, now.month, now.day, parts[0], parts[1]);
                      return slotTime.isAfter(now);
                    }).toList();
                  }

                  return ExpansionTile(
                    collapsedTextColor: Colors.black,
                    iconColor: Colors.teal.shade700,
                    textColor: Colors.teal.shade900,
                    title: Text(
                      'Date: ${_fmtDate(date)}',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${availableSlots.length} slots available',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    children: availableSlots.isEmpty
                        ? [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(AppLocalizations.of(context)!.no_available_times),
                      ),
                    ]
                        : availableSlots.map((slot) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            'Time: $slot',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade900,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                _confirmBook(ctx, slot, doctorId, doctorName, hospitalName, date, d.id),
                            child: const Text('Book'),
                          ),
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

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _confirmBook(BuildContext ctx, String slot, String doctorId,
      String doctorName, String hospitalName, DateTime date, String shiftId) async {
    final loc = AppLocalizations.of(ctx);
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: Text(loc!.confirm_booking),
        content: Text(loc.book_doctor_on_date(_fmtDate(date), doctorName, slot)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.confirm)),
        ],
      ),
    );

    if (confirm == true) {
      await _book(ctx, slot, doctorId, doctorName, hospitalName, date, shiftId);
    }
  }

  Future<void> _book(BuildContext ctx, String slot, String doctorId,
      String doctorName, String hospitalName, DateTime date, String shiftId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final fs = FirebaseFirestore.instance;
      final patientDoc = await fs.collection('users').doc(uid).get();
      final patientName = patientDoc.data()?['name'] ?? 'Unknown';
      final slotParts = slot.split(':').map(int.parse).toList();
      final dt = DateTime(date.year, date.month, date.day, slotParts[0], slotParts[1]);
      final ts = Timestamp.fromDate(dt);

      //  تحقق أن المريض ما عنده موعد مع نفس الدكتور في نفس اليوم
      final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
      final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day + 1));
      final sameDayExisting = await fs
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: uid)
          .where('time', isGreaterThanOrEqualTo: startOfDay)
          .where('time', isLessThan: endOfDay)
          .get();

      if (sameDayExisting.docs.isNotEmpty) {
        final loc = AppLocalizations.of(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(loc!.already_have_appointment(doctorName))),
        );
        return;
      }

      //  تحقق أن الوقت نفسه ما انحجز مسبقًا
      final existing = await fs
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('time', isEqualTo: ts)
          .get();
      if (existing.docs.isNotEmpty) {
        final loc = AppLocalizations.of(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(loc!.time_already_booked)),
        );
        return;
      }

      //  حفظ البيانات
      final apptData = {
        'patientId': uid,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'hospitalName': hospitalName,
        'shiftId': shiftId,
        'time': ts,
        'appointmentDate': ts, // Add appointmentDate for compatibility
        'timeSlot': slot, // Add timeSlot for compatibility
        'status': 'pending', // Changed from 'booked' to 'pending' to match enum
        'createdAt': FieldValue.serverTimestamp(),
      };

      final rootRef = await fs.collection('appointments').add(apptData);
      await fs.collection('users').doc(uid).collection('appointments').doc(rootRef.id).set(apptData);

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

      // Also store in notifications collection for UI
      await fs.collection('notifications').add({
        'userId': doctorId,
        'toRole': 'doctor',
        'doctorId': doctorId,
        'title': 'New Appointment Booking',
        'body': 'Patient $patientName has booked an appointment on $formattedDate at $slot.',
        'appointmentId': rootRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (ctx.mounted) {
        final loc = AppLocalizations.of(ctx);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(loc!.appointment_booked(doctorName, slot)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
        final loc = AppLocalizations.of(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(loc!.error_booking(e.toString()))),
        );
    }
  }
}

// ---------------- HELPERS ----------------
class _SnapList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Widget Function(BuildContext, QueryDocumentSnapshot<Map<String, dynamic>>) itemBuilder;
  const _SnapList({required this.stream, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No results'));
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
    final textColor = Colors.teal.shade50;
    return PrimaryCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title\n$subtitle',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          PrimaryButton(text: actionText, onPressed: onAction),
        ],
      ),
    );
  }
}
