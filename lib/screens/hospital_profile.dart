import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';   // ✅ مفقود وتم إضافته
import '../../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_drawer.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  Map<String, dynamic>? _hospital;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;   // 🔥 الآن ما يعطي خطأ
    final data = await FS.hospitalForAdmin(uid);
    setState(() => _hospital = data);
  }

  Future<void> _editHospital() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_hospital == null) return;

    final nameCtrl = TextEditingController(text: _hospital?['name'] ?? '');
    final emailCtrl = TextEditingController(text: _hospital?['email'] ?? '');
    final addressCtrl = TextEditingController(text: _hospital?['address'] ?? '');
    final aboutCtrl = TextEditingController(text: _hospital?['about'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(t.editHospital, style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: t.name)),
              TextField(controller: emailCtrl, decoration: InputDecoration(labelText: t.email)),
              TextField(controller: addressCtrl, decoration: InputDecoration(labelText: t.address)),
              TextField(controller: aboutCtrl, decoration: InputDecoration(labelText: t.about)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel, style: TextStyle(color: theme.colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FS.hospitals.doc(_hospital!['id']).set({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'about': aboutCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              Navigator.pop(context);
              _load();
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.myProfile,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _editHospital,
            icon: Icon(Icons.edit, color: theme.colorScheme.onPrimary),
          ),
        ],
      ),
      drawer: AdminDrawer(hospitalName: _hospital?['name']),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _hospital == null
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _ProfileBody(data: _hospital!),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProfileBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: theme.cardColor,
          shadowColor: theme.shadowColor.withValues(alpha:0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.local_hospital, color: theme.colorScheme.onPrimary),
                  ),
                  title: Text(
                    data['name'] ?? t.hospital,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  subtitle: Text(data['email'] ?? '', style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(height: 12),

                _kv(context, t.address, data['address'] ?? '—'),
                _kv(context, t.about, data['about'] ?? '—'),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showDetails(context, data),
                    child: Text(t.details),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(
                k,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              )),
          Expanded(child: Text(v, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> d) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              t.hospitalDetails,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            _kv(context, t.name, d['name'] ?? ''),
            _kv(context, t.email, d['email'] ?? ''),
            _kv(context, t.address, d['address'] ?? '—'),
            _kv(context, t.about, d['about'] ?? '—'),
          ],
        ),
      ),
    );
  }
}
