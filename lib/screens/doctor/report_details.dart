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
    final theme = Theme.of(context);

    final Timestamp? ts = reportData['createdAt'];
    final String date = ts != null
        ? "${ts.toDate().year}-${ts.toDate().month.toString().padLeft(2, '0')}-${ts.toDate().day.toString().padLeft(2, '0')}"
        : '—';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.reportDetails,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (theme.brightness == Brightness.light)
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
                _title(t.reportDate, theme),
                _value(date, theme),
                const SizedBox(height: 12),

                _title(t.generalReport, theme),
                _value(reportData['report'] ?? '—', theme),
                const SizedBox(height: 12),

                _title(t.chronicDiseases, theme),
                _value(_formatList(reportData['chronic']), theme),
                const SizedBox(height: 12),

                _title(t.allergies, theme),
                _value(reportData['allergies'] ?? '—', theme),
                const SizedBox(height: 12),

                _title(t.medications, theme),
                _medList(context, t, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =======================  TITLES  =======================

  Widget _title(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        fontSize: 15,
      ),
    );
  }

  // =======================  VALUES  =======================

  Widget _value(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium!.copyWith(
          fontSize: 15,
        ),
      ),
    );
  }

  // =======================  LIST FORMAT  =======================

  String _formatList(dynamic data) {
    if (data == null) return '—';
    if (data is List) return data.join(', ');
    return data.toString();
  }

  // =======================  MEDICINES LIST  =======================

  Widget _medList(BuildContext context, AppLocalizations t, ThemeData theme) {
    final meds = reportData['medicationsList'] ?? [];
    if (meds.isEmpty) {
      return Text(
        '—',
        style: theme.textTheme.bodyMedium!.copyWith(fontSize: 15),
      );
    }

    return Column(
      children: meds.map<Widget>((m) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• ${m['name'] ?? ''}",
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text("${t.dosage}: ${m['dosage'] ?? ''}",
                  style: theme.textTheme.bodyMedium),
              Text("${t.days}: ${m['days'] ?? ''}",
                  style: theme.textTheme.bodyMedium),
              Text("${t.notes}: ${m['notes'] ?? ''}",
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      }).toList(),
    );
  }
}
