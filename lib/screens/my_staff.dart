import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../services/firestore_service.dart';
import '../routes.dart';
import '../widgets/admin_drawer.dart';

class MyStaffScreen extends StatefulWidget {
  const MyStaffScreen({super.key});
  @override
  State<MyStaffScreen> createState() => _MyStaffScreenState();
}

class _MyStaffScreenState extends State<MyStaffScreen> {
  String q = '';
  String? hospId;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FS.hospitalForAdmin(uid).then((d) => setState(() => hospId = d?['id']));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.myStaff)),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.regDoctor),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(t.addDoctor),
      ),
      body: hospId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (s) => setState(() => q = s.toLowerCase()),
              decoration: InputDecoration(
                hintText: t.search,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.black.withOpacity(.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FS.doctorsStream(hospId!),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs.where((d) {
                  final m = d.data() as Map<String, dynamic>;
                  final name =
                  (m['name'] ?? '').toString().toLowerCase();
                  final spec =
                  (m['specialization'] ?? '').toString().toLowerCase();
                  return name.contains(q) || spec.contains(q);
                }).toList();

                if (docs.isEmpty) {
                  return Center(child: Text(t.noDoctors));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final m = d.data() as Map<String, dynamic>;
                    return _DoctorTile(
                      uid: d.id,
                      name: m['name'] ?? 'Doctor',
                      spec: m['specialization'] ?? '',
                      approved: (m['approved'] ?? false) == true,
                      email: m['email'] ?? '',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  final String uid, name, spec, email;
  final bool approved;
  const _DoctorTile(
      {required this.uid,
        required this.name,
        required this.spec,
        required this.email,
        required this.approved});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D515C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.medical_services, color: Colors.white)),
        title: Text(name,
            style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(spec, style: const TextStyle(color: Colors.white70)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!approved)
              Container(
                margin: const EdgeInsets.only(right: 6),
                child: Chip(
                    label: Text(t.pending),
                    backgroundColor: Colors.orangeAccent),
              ),

            // Details
            TextButton(
              onPressed: () => _showDetails(context),
              child: Text(t.details, style: const TextStyle(color: Colors.white)),
            ),

            const SizedBox(width: 6),

            // Delete
            TextButton(
              onPressed: () => _confirmDelete(context),
              child: Text(t.delete, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.doctorDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('${t.specialization}: $spec'),
            Text('${t.email}: $email'),
            Text('${t.approved}: $approved'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.deleteDoctor),
        content: Text(t.deleteDoctorConfirm),
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
      await FS.deleteDoctor(uid);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.doctorDeleted)));
      }
    }
  }
}
