import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = await FS.hospitalForAdmin(uid);
    setState(() => _hospital = data);
  }

  Future<void> _editHospital() async {
    final t = AppLocalizations.of(context)!;

    if (_hospital == null) return;

    final nameCtrl = TextEditingController(text: _hospital?['name'] ?? '');
    final emailCtrl = TextEditingController(text: _hospital?['email'] ?? '');
    final addressCtrl = TextEditingController(text: _hospital?['address'] ?? '');
    final aboutCtrl = TextEditingController(text: _hospital?['about'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.editHospital),
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
                  controller: addressCtrl,
                  decoration: InputDecoration(labelText: t.address)),
              TextField(
                  controller: aboutCtrl,
                  decoration: InputDecoration(labelText: t.about)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(t.myProfile),
        actions: [
          IconButton(
            onPressed: _editHospital,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      drawer: AdminDrawer(hospitalName: _hospital?['name']),
      body: _hospital == null
          ? const Center(child: CircularProgressIndicator())
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
                    radius: 26,
                    backgroundColor: Color(0xFF2D515C),
                    child: Icon(Icons.local_hospital, color: Colors.white),
                  ),
                  title: Text(
                    data['name'] ?? t.hospital,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF2D515C),
                    ),
                  ),
                  subtitle: Text(data['email'] ?? ''),
                ),
                const SizedBox(height: 12),
                _kv(t.address, data['address'] ?? '—'),
                _kv(t.about, data['about'] ?? '—'),
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

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
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
            Text(
              t.hospitalDetails,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _kv(t.name, d['name'] ?? ''),
            _kv(t.email, d['email'] ?? ''),
            _kv(t.address, d['address'] ?? '—'),
            _kv(t.about, d['about'] ?? '—'),
          ],
        ),
      ),
    );
  }
}
