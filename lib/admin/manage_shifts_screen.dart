import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/admin_drawer.dart';
import '../services/firestore_service.dart';

class ManageShiftsScreen extends StatefulWidget {
  const ManageShiftsScreen({super.key});

  @override
  State<ManageShiftsScreen> createState() => _ManageShiftsScreenState();
}

class _ManageShiftsScreenState extends State<ManageShiftsScreen> {
  String? hospId;

  String? _selectedDoctorId;
  String? _selectedDoctorName;
  String? _selectedDoctorSpec;

  DateTime? _selectedDate;
  TimeOfDay? _start;
  TimeOfDay? _end;

  bool _saving = false;
  String _search = '';
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FS.hospitalForAdmin(uid).then((d) {
      setState(() => hospId = d?['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: Text(t.manageShifts),
        actions: [
          IconButton(
            tooltip: t.filterByDateRange,
            icon: const Icon(Icons.filter_alt),
            onPressed: _pickRange,
          ),
          IconButton(
            tooltip: t.clearFilters,
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() => _range = null),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hospId == null ? null : _openCreateDialog,
        icon: const Icon(Icons.add),
        label: Text(t.addShift),
      ),
      body: hospId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              onChanged: (s) => setState(() => _search = s.toLowerCase()),
              decoration: InputDecoration(
                hintText: t.searchDoctorOrSpecialization,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surface.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _ShiftsList(
              hospitalId: hospId!,
              search: _search,
              range: _range,
              onEdit: (docId, data) => _openEditDialog(docId, data),
              onDelete: (docId) => _deleteShift(docId),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final res = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
      _range ?? DateTimeRange(start: now, end: now.add(const Duration(days: 7))),
    );
    if (res != null) setState(() => _range = res);
  }

  // ===================== إنشاء شفت =====================
  Future<void> _openCreateDialog() async {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    _selectedDoctorId = null;
    _selectedDoctorName = null;
    _selectedDoctorSpec = null;
    _selectedDate = null;
    _start = null;
    _end = null;

    final doctorsSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('hospitalId', isEqualTo: hospId)
        .where('approved', isEqualTo: true)
        .get();

    final doctors = doctorsSnap.docs
        .map((d) => {
      'id': d.id,
      'name': (d.data()['name'] ?? 'Doctor') as String,
      'specialization': (d.data()['specialization'] ?? '') as String,
      'email': (d.data()['email'] ?? '') as String,
    })
        .toList();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setStateDialog) => AlertDialog(
          title: Text(t.addShift),
          backgroundColor: cs.surface,
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedDoctorId,
                  items: doctors
                      .map(
                        (m) => DropdownMenuItem<String>(
                      value: m['id'] as String,
                      child: Text('${m['name']} • ${m['specialization']}'),
                    ),
                  )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final m = doctors.firstWhere((x) => x['id'] == v);
                    setStateDialog(() {
                      _selectedDoctorId = v;
                      _selectedDoctorName = m['name'];
                      _selectedDoctorSpec = m['specialization'];
                    });
                  },
                  decoration: InputDecoration(labelText: t.doctor),
                ),
                const SizedBox(height: 10),
                _PickerRow(
                  label: t.date,
                  value:
                  _selectedDate == null ? t.selectDate : _fmtDate(_selectedDate!),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 1),
                      initialDate: _selectedDate ?? now,
                    );
                    if (picked != null) setStateDialog(() => _selectedDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                _PickerRow(
                  label: t.start,
                  value: _start == null ? t.selectTime : _fmtTime(_start!),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _start ?? const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null) setStateDialog(() => _start = picked);
                  },
                ),
                const SizedBox(height: 10),
                _PickerRow(
                  label: t.end,
                  value: _end == null ? t.selectTime : _fmtTime(_end!),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _end ?? const TimeOfDay(hour: 16, minute: 0),
                    );
                    if (picked != null) setStateDialog(() => _end = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                if (_selectedDoctorId == null ||
                    _selectedDate == null ||
                    _start == null ||
                    _end == null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.completeAllFields)),
                  );
                  return;
                }

                final startMin = _start!.hour * 60 + _start!.minute;
                final endMin = _end!.hour * 60 + _end!.minute;
                if (endMin <= startMin) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.endTimeAfterStart)),
                  );
                  return;
                }

                setState(() => _saving = true);
                try {
                  final dateStr = _fmtDate(_selectedDate!);
                  final ref = FirebaseFirestore.instance
                      .collection('hospitals')
                      .doc(hospId)
                      .collection('shifts')
                      .doc();

                  await ref.set({
                    'doctorId': _selectedDoctorId,
                    'doctorName': _selectedDoctorName,
                    'specialization': _selectedDoctorSpec,
                    'date': dateStr,
                    'dateTs': Timestamp.fromDate(
                      DateTime(
                        _selectedDate!.year,
                        _selectedDate!.month,
                        _selectedDate!.day,
                      ),
                    ),
                    'day': _weekdayName(_selectedDate!.weekday),
                    'startTime': _fmtTime(_start!),
                    'endTime': _fmtTime(_end!),
                    'status': 'available',
                    'createdAt': FieldValue.serverTimestamp(),
                    'hospitalId': hospId,
                  });

                  navigator.pop(); // close dialog
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.shiftAdded)),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('${t.error}: $e')),
                  );
                } finally {
                  setState(() => _saving = false);
                }
              },
              child: Text(_saving ? t.saving : t.save),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== تعديل شفت =====================
  Future<void> _openEditDialog(String shiftId, Map<String, dynamic> data) async {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    _selectedDoctorId = data['doctorId'] as String?;
    _selectedDoctorName = data['doctorName'] as String?;
    _selectedDoctorSpec = data['specialization'] as String?;
    _selectedDate = _parseDate(data['date'] as String?);
    _start = _parseTime(data['startTime'] as String?);
    _end = _parseTime(data['endTime'] as String?);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setStateDialog) => AlertDialog(
          title: Text(t.edit),
          backgroundColor: cs.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PickerRow(
                label: t.date,
                value:
                _selectedDate == null ? t.selectDate : _fmtDate(_selectedDate!),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 1),
                    initialDate: _selectedDate ?? now,
                  );
                  if (picked != null) setStateDialog(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 10),
              _PickerRow(
                label: t.start,
                value: _start == null ? t.selectTime : _fmtTime(_start!),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _start ?? const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (picked != null) setStateDialog(() => _start = picked);
                },
              ),
              const SizedBox(height: 10),
              _PickerRow(
                label: t.end,
                value: _end == null ? t.selectTime : _fmtTime(_end!),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _end ?? const TimeOfDay(hour: 16, minute: 0),
                  );
                  if (picked != null) setStateDialog(() => _end = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                if (_selectedDate == null || _start == null || _end == null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.completeAllFields)),
                  );
                  return;
                }

                final startMin = _start!.hour * 60 + _start!.minute;
                final endMin = _end!.hour * 60 + _end!.minute;
                if (endMin <= startMin) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.endTimeAfterStart)),
                  );
                  return;
                }

                setState(() => _saving = true);
                try {
                  final dateStr = _fmtDate(_selectedDate!);

                  await FirebaseFirestore.instance
                      .collection('hospitals')
                      .doc(hospId)
                      .collection('shifts')
                      .doc(shiftId)
                      .update({
                    'date': dateStr,
                    'dateTs': Timestamp.fromDate(
                      DateTime(
                        _selectedDate!.year,
                        _selectedDate!.month,
                        _selectedDate!.day,
                      ),
                    ),
                    'day': _weekdayName(_selectedDate!.weekday),
                    'startTime': _fmtTime(_start!),
                    'endTime': _fmtTime(_end!),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.shiftUpdated)),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('${t.error}: $e')),
                  );
                } finally {
                  setState(() => _saving = false);
                }
              },
              child: Text(_saving ? t.saving : t.update),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== حذف شفت =====================
  Future<void> _deleteShift(String shiftId) async {
    final t = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('hospitals')
          .doc(hospId)
          .collection('shifts')
          .doc(shiftId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.shiftDeleted)),
        );
      }
    }
  }

  // ===================== Helpers =====================
  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    final p = s.split('-');
    if (p.length != 3) return null;
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    final p = s.split(':');
    if (p.length != 2) return null;
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}

// ===================== Picker Row =====================
class _PickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(value)),
            const Icon(Icons.edit_calendar_outlined),
          ],
        ),
      ),
    );
  }
}

// ===================== قائمة الشفتات =====================
class _ShiftsList extends StatelessWidget {
  final String hospitalId;
  final String search;
  final DateTimeRange? range;
  final void Function(String shiftId, Map<String, dynamic> data) onEdit;
  final Future<void> Function(String shiftId) onDelete;

  const _ShiftsList({
    required this.hospitalId,
    required this.search,
    required this.range,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final ref = FirebaseFirestore.instance
        .collection('hospitals')
        .doc(hospitalId)
        .collection('shifts');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snap.data!.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((m) {
          final doctor = (m['doctorName'] ?? '').toString().toLowerCase();
          final spec = (m['specialization'] ?? '').toString().toLowerCase();
          final okSearch =
              search.isEmpty || doctor.contains(search) || spec.contains(search);

          if (range != null) {
            final dateStr = (m['date'] ?? '') as String;
            final dt = _ManageShiftsScreenState._parseDate(dateStr);
            if (dt == null) return false;
            final inRange =
                !dt.isBefore(range!.start) && !dt.isAfter(range!.end);
            return okSearch && inRange;
          }

          return okSearch;
        }).toList()
          ..sort((a, b) {
            final ad =
            _ManageShiftsScreenState._parseDate(a['date'] as String?);
            final bd =
            _ManageShiftsScreenState._parseDate(b['date'] as String?);
            final cmp = (ad ?? DateTime(1900)).compareTo(bd ?? DateTime(1900));
            if (cmp != 0) return cmp;
            final at = (a['startTime'] ?? '') as String;
            final bt = (b['startTime'] ?? '') as String;
            return at.compareTo(bt);
          });

        if (list.isEmpty) {
          return Center(child: Text(t.noShifts));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final m = list[i];
            final id = m['id'] as String;
            final docName = (m['doctorName'] ?? 'Doctor') as String;
            final spec = (m['specialization'] ?? '') as String;
            final date = (m['date'] ?? '') as String;
            final day = (m['day'] ?? '') as String;
            final start = (m['startTime'] ?? '') as String;
            final end = (m['endTime'] ?? '') as String;
            final status = (m['status'] ?? 'available') as String;

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? cs.surface : const Color(0xFF2D515C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(
                  '$docName  •  $spec',
                  style: TextStyle(
                    color: isDark ? cs.onSurface : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$day  •  $date  •  $start - $end  •  $status',
                  style: TextStyle(
                    color: isDark
                        ? cs.onSurface.withValues(alpha: 0.7)
                        : Colors.white70,
                  ),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () =>
                          onEdit(id, Map<String, dynamic>.from(m)),
                      child: Text(
                        t.edit,
                        style: TextStyle(
                          color: isDark ? cs.primary : Colors.white,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onDelete(id),
                      child: Text(
                        t.delete,
                        style: TextStyle(
                          color: isDark ? cs.error : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
