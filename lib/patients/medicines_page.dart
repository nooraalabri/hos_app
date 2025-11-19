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

    final cs = Theme.of(context).colorScheme;

    // Firestore query
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

          // ===================== FILTER TOGGLES =====================
          ToggleButtons(
            borderRadius: BorderRadius.circular(10),
            borderColor: cs.primary,
            selectedBorderColor: cs.primary,
            fillColor: cs.primary.withValues(alpha: 0.15), // Material 3
            selectedColor: cs.primary,
            color: cs.onSurface.withValues(alpha: 0.7),
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

          // ===================== LIST OF MEDICINES =====================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: col.snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: cs.primary));
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      t.noMedicines,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }

                final docs = snap.data!.docs;

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
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: cs.onSurface,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '${t.dosage}: ${m['dosage'] ?? ''}',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          Text(
                            '${t.schedule}: ${m['schedule'] ?? ''}',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          Text(
                            '${t.activeLabel}: ${m['active'] == true ? t.yes : t.no}',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
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
