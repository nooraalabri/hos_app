import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hos_app/patients/ui.dart';
import '../../l10n/app_localizations.dart';
import 'patient_drawer.dart';

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

    return AppScaffold(
      title: t.myMedicines,
      drawer: const PatientDrawer(),

      body: Column(
        children: [
          const SizedBox(height: 12),

          // -------- FILTER BUTTONS --------
          ToggleButtons(
            borderRadius: BorderRadius.circular(10),
            borderColor: cs.primary,
            selectedBorderColor: cs.primary,
            fillColor: cs.primary.withValues(alpha: 0.1),
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

          // -------- MEDICINES LIST --------
          Expanded(
            child: FutureBuilder(
              future: _loadAllMedicines(uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }

                final meds = snap.data as List<Map<String, dynamic>>;

                if (meds.isEmpty) {
                  return Center(
                    child: Text(
                      t.noMedicines,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }

                final now = DateTime.now();

                final filtered = meds.where((m) {
                  final start = m['startDate'];
                  final end = m['endDate'];

                  bool isActive = false;

                  if (start != null && end != null) {
                    isActive = now.isAfter(start) && now.isBefore(end);
                  }

                  return showActive ? isActive : true;
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    return _buildMedicineCard(
                      context,
                      filtered[i],
                      t,
                      cs,
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

  // -------- LOAD ALL MEDICINES --------
  Future<List<Map<String, dynamic>>> _loadAllMedicines(String uid) async {
    List<Map<String, dynamic>> meds = [];

    // ---------- 1) OLD MEDICINES ----------
    final old = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .get();

    for (var doc in old.docs) {
      final d = doc.data();
      meds.add({
        'name': d['name'],
        'dosage': d['dosage'],
        'notes': d['notes'] ?? '',
        'startDate': (d['startDate'] as Timestamp?)?.toDate(),
        'endDate': (d['endDate'] as Timestamp?)?.toDate(),
      });
    }

    // ---------- 2) NEW MEDICINES FROM REPORTS ----------
    final reports = await FirebaseFirestore.instance
        .collection('reports')
        .where('patientId', isEqualTo: uid)
        .get();

    for (var r in reports.docs) {
      final data = r.data();
      if (data['medicationsList'] != null) {
        for (var m in data['medicationsList']) {
          meds.add({
            'name': m['name'],
            'dosage': m['dosage'],
            'notes': m['notes'] ?? '',
            'startDate': (m['startDate'] as Timestamp?)?.toDate(),
            'endDate': (m['endDate'] as Timestamp?)?.toDate(),
          });
        }
      }
    }

    return meds;
  }

  // -------- MEDICINE CARD --------
  Widget _buildMedicineCard(BuildContext context, Map<String, dynamic> m,
      AppLocalizations t, ColorScheme cs) {
    final start = m['startDate'];
    final end = m['endDate'];

    int totalDays = 0;
    int passedDays = 0;

    if (start != null && end != null) {
      totalDays = end.difference(start).inDays + 1;
      passedDays = DateTime.now().difference(start).inDays + 1;
    }

    double progress = 0;
    if (totalDays > 0) {
      progress = (passedDays / totalDays).clamp(0, 1).toDouble();
    }

    final remaining = (totalDays - passedDays).clamp(0, totalDays);

    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // medicine name
          Text(
            m['name'] ?? "",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "${t.dosage}: ${m['dosage']}",
            style: TextStyle(color: cs.onSurfaceVariant),
          ),

          Text(
            "${t.medicineNotes}: ${m['notes']}",
            style: TextStyle(color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 12),

          if (start != null && end != null) ...[
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: cs.primary.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),

            const SizedBox(height: 6),

            Text(
              "${t.daysPassed}: $passedDays / $totalDays   —   ${t.remaining}: $remaining",
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),

            Text(
              "${t.dateRange}: ${start.day}/${start.month}/${start.year}  →  ${end.day}/${end.month}/${end.year}",
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
