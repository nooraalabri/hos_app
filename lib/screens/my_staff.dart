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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.myStaff,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),

      drawer: const AdminDrawer(),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.regDoctor),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(t.addDoctor),
      ),

      backgroundColor: theme.scaffoldBackgroundColor,

      body: hospId == null
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : Column(
        children: [
          // ---------------- SEARCH BOX ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (s) => setState(() => q = s.toLowerCase()),
              decoration: InputDecoration(
                hintText: t.search,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ---------------- STAFF LIST ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FS.doctorsStream(hospId!),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }

                final docs = snap.data!.docs.where((d) {
                  final m = d.data() as Map<String, dynamic>;
                  final name = (m['name'] ?? '').toString().toLowerCase();
                  final spec = (m['specialization'] ?? '').toString().toLowerCase();
                  return name.contains(q) || spec.contains(q);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      t.noDoctors,
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
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

// =============================================================
//                           DOCTOR TILE
// =============================================================
class _DoctorTile extends StatelessWidget {
  final String uid, name, spec, email;
  final bool approved;

  const _DoctorTile({
    required this.uid,
    required this.name,
    required this.spec,
    required this.email,
    required this.approved,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.onPrimary.withValues(alpha:.25),
          child: Icon(Icons.medical_services, color: theme.colorScheme.onPrimary),
        ),

        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          spec,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha:.8),
          ),
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!approved)
              Container(
                margin: const EdgeInsets.only(right: 6),
                child: Chip(
                  label: Text(t.pending),
                  labelStyle: const TextStyle(color: Colors.white),
                  backgroundColor: Colors.orange,
                ),
              ),

            TextButton(
              onPressed: () => _showDetails(context),
              child: Text(t.details, style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),

            const SizedBox(width: 6),

            TextButton(
              onPressed: () => _confirmDelete(context),
              child: Text(t.delete, style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(t.doctorDetails, style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text("${t.specialization}: $spec"),
            Text("${t.email}: $email"),
            Text("${t.approved}: $approved"),
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
    final theme = Theme.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
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
