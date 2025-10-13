import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    FS.hospitalForAdmin(uid).then((d)=>setState(()=>hospId = d?['id']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Staff')),
      drawer: AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.regDoctor),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add doctor'),
      ),
      body: hospId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (s)=> setState(()=> q = s.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.black.withOpacity(.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FS.doctorsStream(hospId!),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs.where((d){
                  final m = d.data() as Map<String,dynamic>;
                  final name = (m['name'] ?? '').toString().toLowerCase();
                  final spec = (m['specialization'] ?? '').toString().toLowerCase();
                  return name.contains(q) || spec.contains(q);
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No doctors'));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __)=> const SizedBox(height: 8),
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, i){
                    final d = docs[i];
                    final m = d.data() as Map<String,dynamic>;
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
  const _DoctorTile({required this.uid, required this.name, required this.spec, required this.email, required this.approved});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF2D515C), borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.medical_services, color: Colors.white)),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(spec, style: const TextStyle(color: Colors.white70)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(!approved) Container(
              margin: const EdgeInsets.only(right: 6),
              child: const Chip(label: Text('pending'), backgroundColor: Colors.orangeAccent),
            ),
            TextButton(
              onPressed: ()=> _showDetails(context),
              child: const Text('details', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: ()=> _confirmDelete(context),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context){
    showDialog(
      context: context,
      builder: (_)=> AlertDialog(
        title: const Text('Doctor details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Specialization: $spec'),
            Text('E-mail: $email'),
            Text('Approved: $approved'),
          ],
        ),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_)=> AlertDialog(
        title: const Text('Delete doctor'),
        content: const Text('Are you sure you want to delete this doctor?'),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Cancel')),
          ElevatedButton(onPressed: ()=> Navigator.pop(context,true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await FS.deleteDoctor(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor deleted')));
      }
    }
  }
}
