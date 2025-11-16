import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';

class ReportDetails extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final String reportId;

  const ReportDetails({
    super.key,
    required this.reportData,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final Timestamp? ts = reportData['createdAt'];
    final String date = ts != null
        ? "${ts.toDate().year}-${ts.toDate().month.toString().padLeft(2, '0')}-${ts.toDate().day.toString().padLeft(2, '0')}"
        : '—';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.reportDetails,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2D515C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFE8F2F3),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(t.reportDate),
                _value(date),
                const SizedBox(height: 12),

                _title(t.generalReport),
                _value(reportData['report'] ?? '—'),
                const SizedBox(height: 12),

                _title(t.chronicDiseases),
                _value(_formatList(reportData['chronic'])),
                const SizedBox(height: 12),

                _title(t.allergies),
                _value(reportData['allergies'] ?? '—'),
                const SizedBox(height: 12),

                _title(t.medications),
                _medList(context, t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D515C),
        fontSize: 15,
      ),
    );
  }

  Widget _value(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }

  String _formatList(dynamic data) {
    if (data == null) return '—';
    if (data is List) return data.join(', ');
    return data.toString();
  }

  Widget _medList(BuildContext context, AppLocalizations t) {
    final meds = reportData['medicationsList'] ?? [];
    if (meds.isEmpty) return const Text('—', style: TextStyle(fontSize: 15));

    return Column(
      children: meds.map<Widget>((m) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF4F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ${m['name'] ?? ''}",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text("${t.dosage}: ${m['dosage'] ?? ''}"),
              Text("${t.days}: ${m['days'] ?? ''}"),
              Text("${t.notes}: ${m['notes'] ?? ''}"),
            ],
          ),
        );
      }).toList(),
    );
  }
}
