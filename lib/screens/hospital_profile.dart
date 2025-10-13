import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    if (_hospital == null) return;

    final nameCtrl = TextEditingController(text: _hospital?['name'] ?? '');
    final emailCtrl = TextEditingController(text: _hospital?['email'] ?? '');
    final locationCtrl = TextEditingController(text: _hospital?['location'] ?? '');
    final aboutCtrl = TextEditingController(text: _hospital?['about'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Hospital"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: "Location")),
              TextField(controller: aboutCtrl, decoration: const InputDecoration(labelText: "About")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FS.hospitals.doc(_hospital!['id']).set({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'location': locationCtrl.text.trim(),
                'about': aboutCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              Navigator.pop(context);
              _load(); // تحديث البيانات بعد التعديل
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: _editHospital,
            icon: const Icon(Icons.edit),
          )
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
    final status = data['status'] ?? 'pending';
    final chips = {
      'approved': Colors.green,
      'pending': Colors.orange,
      'rejected': Colors.red,
    };

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
                  leading: const CircleAvatar(radius: 26, child: Icon(Icons.local_hospital)),
                  title: Text(data['name'] ?? 'Hospital'),
                  subtitle: Text(data['email'] ?? ''),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: (chips[status] ?? Colors.grey).withOpacity(.15),
                    labelStyle: TextStyle(color: chips[status] ?? Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                _kv('Location', data['location'] ?? '—'),
                _kv('About', data['about'] ?? '—'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showDetails(context, data),
                    child: const Text('details'),
                  ),
                )
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
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Hospital details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _kv('Name', d['name'] ?? ''),
            _kv('Email', d['email'] ?? ''),
            _kv('Location', d['location'] ?? '—'),
            _kv('About', d['about'] ?? '—'),
            _kv('Status', d['status'] ?? '—'),
          ],
        ),
      ),
    );
  }
}
