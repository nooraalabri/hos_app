import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../services/firestore_service.dart';

class HeadAdminReportsScreen extends StatefulWidget {
  const HeadAdminReportsScreen({super.key});

  @override
  State<HeadAdminReportsScreen> createState() => _HeadAdminReportsScreenState();
}

class _HeadAdminReportsScreenState extends State<HeadAdminReportsScreen> {
  ReportPeriod period = ReportPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.dashboard,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),

      backgroundColor: theme.scaffoldBackgroundColor,

      body: FutureBuilder<Map<String, int>>(
        future: FS.statsForHeadAdmin(period: period),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          final m = snap.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _statCard(
                      context,
                      t.hospitalsApproved,
                      m['hospitalsApproved'] ?? 0,
                      Icons.local_hospital,
                      theme.colorScheme.primary,
                    ),
                    _statCard(
                      context,
                      t.hospitalsPending,
                      m['hospitalsPending'] ?? 0,
                      Icons.pending,
                      theme.colorScheme.tertiary,
                    ),
                    _statCard(
                      context,
                      t.doctorsApproved,
                      m['doctorsApproved'] ?? 0,
                      Icons.medical_information,
                      theme.colorScheme.secondary,
                    ),
                    _statCard(
                      context,
                      t.doctorsPending,
                      m['doctorsPending'] ?? 0,
                      Icons.pending_actions,
                      theme.colorScheme.error,
                    ),
                    _statCard(
                      context,
                      t.patientsTotal,
                      m['patientsTotal'] ?? 0,
                      Icons.people,
                      theme.colorScheme.primaryContainer,
                    ),
                    _statCard(
                      context,
                      t.newUsers,
                      m['newUsers'] ?? 0,
                      Icons.person_add,
                      theme.colorScheme.inversePrimary,
                    ),
                    _statCard(
                      context,
                      t.newHospitals,
                      m['newHospitals'] ?? 0,
                      Icons.apartment,
                      theme.colorScheme.secondaryContainer,
                    ),
                    _statCard(
                      context,
                      t.appointments,
                      m['appointments'] ?? 0,
                      Icons.event_available,
                      theme.colorScheme.surfaceTint,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SegmentedButton<ReportPeriod>(
                  segments: [
                    ButtonSegment(
                      value: ReportPeriod.weekly,
                      label: Text(t.weekly),
                    ),
                    ButtonSegment(
                      value: ReportPeriod.monthly,
                      label: Text(t.monthly),
                    ),
                    ButtonSegment(
                      value: ReportPeriod.yearly,
                      label: Text(t.yearly),
                    ),
                  ],
                  selected: {period},
                  onSelectionChanged: (s) {
                    setState(() => period = s.first);
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  //--------------- STAT CARD -----------------

  Widget _statCard(
      BuildContext context,
      String title,
      int value,
      IconData icon,
      Color bgColor,
      ) {
    final textColor =
    ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: bgColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: textColor),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
