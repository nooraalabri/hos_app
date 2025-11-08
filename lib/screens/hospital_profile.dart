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
    final addressCtrl = TextEditingController(text: _hospital?['address'] ?? '');
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
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Address")),
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
                'address': addressCtrl.text.trim(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                    data['name'] ?? 'Hospital',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF2D515C),
                    ),
                  ),
                  subtitle: Text(data['email'] ?? ''),
                ),
                const SizedBox(height: 12),
                _kv('Address', data['address'] ?? '—'),
                _kv('About', data['about'] ?? '—'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showDetails(context, data),
                    child: const Text('details'),
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
            _kv('Address', d['address'] ?? '—'),
            _kv('About', d['about'] ?? '—'),
          ],
        ),
      ),
    );
  }
}
