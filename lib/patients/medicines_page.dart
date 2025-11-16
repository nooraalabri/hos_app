// lib/patients/medicines_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    var col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .orderBy('createdAt', descending: true);

    if (showActive) col = col.where('active', isEqualTo: true);

    return AppScaffold(
      title: t.myMedicines,
      drawer: const PatientDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 12),

          ToggleButtons(
            borderRadius: BorderRadius.circular(10),
            isSelected: [!showActive, showActive],
            onPressed: (i) => setState(() => showActive = (i == 1)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(t.all),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(t.active),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: col.snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return Center(child: Text(t.noMedicines));
                }

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
                          Text(
                            m['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text('${t.dosage}: ${m['dosage'] ?? ''}'),
                          Text('${t.schedule}: ${m['schedule'] ?? ''}'),
                          Text('${t.activeLabel}: ${m['active'] == true ? t.yes : t.no}'),
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
