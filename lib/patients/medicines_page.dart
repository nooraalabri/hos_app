// lib/patients/medicines_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'patient_drawer.dart';
import 'ui.dart';

class MedicinesPage extends StatefulWidget {
  static const route = '/patient/medicines';
  const MedicinesPage({super.key});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  bool showActive = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    var col = FirebaseFirestore.instance.collection('users').doc(uid).collection('medicines').orderBy('createdAt', descending: true);
    if (showActive) col = col.where('active', isEqualTo: true);

    return AppScaffold(
      title: 'My medicines',
      drawer: const PatientDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ToggleButtons(
            borderRadius: BorderRadius.circular(10),
            isSelected: [!showActive, showActive],
            onPressed: (i) => setState(() => showActive = (i == 1)),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('All')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Active')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: col.snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No medicines'));
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final m = docs[i].data();
                    return PrimaryCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Dosage: ${m['dosage'] ?? ''}'),
                          Text('Schedule: ${m['schedule'] ?? ''}'),
                          Text('Active: ${m['active'] == true ? 'Yes' : 'No'}'),
                        ],
                      ),
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
