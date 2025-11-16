import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'doctor/my_shifts_screen.dart';
import 'doctor/reviews.dart';
import 'doctor/weekly_shifts_screen.dart';
import 'settings_screen.dart';

class DoctorHome extends StatefulWidget {
  final String doctorId;
  const DoctorHome({super.key, required this.doctorId});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  Map<String, dynamic>? _doctor;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.doctorId)
        .get();
    if (doc.exists) setState(() => _doctor = doc.data());
  }

  Future<void> _editDoctor() async {
    if (_doctor == null) return;

    final nameCtrl = TextEditingController(text: _doctor?['name'] ?? '');
    final emailCtrl = TextEditingController(text: _doctor?['email'] ?? '');
    final specializationCtrl =
    TextEditingController(text: _doctor?['specialization'] ?? '');
    final bioCtrl = TextEditingController(text: _doctor?['bio'] ?? '');

    final t = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.editProfile),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: t.name)),
              TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(labelText: t.email)),
              TextField(
                  controller: specializationCtrl,
                  decoration: InputDecoration(labelText: t.specialization)),
              TextField(
                  controller: bioCtrl,
                  decoration: InputDecoration(labelText: t.bio)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.doctorId)
                  .set({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'specialization': specializationCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              Navigator.pop(context);
              _loadProfile();
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.doctorProfile),
        actions: [
          IconButton(onPressed: _editDoctor, icon: const Icon(Icons.edit)),
        ],
      ),
      drawer: _DoctorDrawer(doctorId: widget.doctorId),
      body: _doctor == null
          ? const Center(child: CircularProgressIndicator())
          : _DoctorProfileBody(data: _doctor!, doctorId: widget.doctorId),
    );
  }
}

class _DoctorProfileBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final String doctorId;

  const _DoctorProfileBody({required this.data, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final status = data['approved'] == true
        ? t.approved
        : t.pending;

    final statusColor =
    data['approved'] == true ? Colors.green : Colors.orange;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                      radius: 26, child: Icon(Icons.person)),
                  title: Text(data['name'] ?? t.name),
                  subtitle: Text(data['email'] ?? ''),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: statusColor.withOpacity(.15),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ),
                const SizedBox(height: 12),
                _kv(t.specialization, data['specialization'] ?? '—'),
                _kv(t.bio, data['bio'] ?? '—'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showDetails(context, data),
                    child: Text(t.details),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        Text(t.quickAccess,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _linkTile(
          context,
          icon: Icons.calendar_today,
          title: t.myShifts,
          screen: MyShiftsScreen(doctorId: doctorId),
        ),
        _linkTile(
          context,
          icon: Icons.date_range,
          title: t.weeklyShifts,
          screen: ShiftsOverviewScreen(doctorId: doctorId),
        ),
        _linkTile(
          context,
          icon: Icons.reviews,
          title: t.reviews,
          screen: ReviewsScreen(doctorId: doctorId),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 120,
            child: Text(k,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(v)),
      ],
    ),
  );

  void _showDetails(BuildContext context, Map<String, dynamic> d) {
    final t = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(t.doctorDetails,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _kv(t.name, d['name'] ?? ''),
            _kv(t.email, d['email'] ?? ''),
            _kv(t.specialization, d['specialization'] ?? ''),
            _kv(t.bio, d['bio'] ?? '—'),
            _kv(t.status, d['approved'] == true ? t.approved : t.pending),
          ],
        ),
      ),
    );
  }

  Widget _linkTile(BuildContext context,
      {required IconData icon,
        required String title,
        required Widget screen}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2D515C)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}

class _DoctorDrawer extends StatelessWidget {
  final String doctorId;
  const _DoctorDrawer({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2D515C)),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(t.doctorMenu,
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(t.home),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(t.myShifts),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyShiftsScreen(doctorId: doctorId)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(t.weeklyShifts),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ShiftsOverviewScreen(doctorId: doctorId)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.reviews),
            title: Text(t.reviews),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ReviewsScreen(doctorId: doctorId)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(t.settings),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(t.logout),
            onTap: () => AuthService.logoutAndGoWelcome(context),
          ),
        ],
      ),
    );
  }
}
