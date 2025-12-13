import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../admin/hospital_doctor_reports_screen.dart';
import 'package:hos_app/routes.dart'; // ⬅ مهم جداً
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_drawer.dart';
import '../services/firestore_service.dart';

enum Period { weekly, monthly, yearly }

class HospitalReportsScreen extends StatefulWidget {
  const HospitalReportsScreen({super.key});

  @override
  State<HospitalReportsScreen> createState() => _HospitalReportsScreenState();
}

class _HospitalReportsScreenState extends State<HospitalReportsScreen> {
  Period p = Period.weekly;
  String? hospId;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).get().then((doc) {
      if (doc.exists) {
        final hid = doc.data()?['hospitalId'];
        if (mounted) setState(() => hospId = hid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final periodKey = switch (p) {
      Period.weekly => "weekly",
      Period.monthly => "monthly",
      Period.yearly => "yearly",
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.hospitalReports,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),

      drawer: const AdminDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,

      body: hospId == null
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : FutureBuilder<Map<String, int>>(
        future: FS.statsForHospital(hospId!, periodKey),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
                child: CircularProgressIndicator(
                    color: theme.colorScheme.primary));
          }

          final m = snap.data ?? {'new': 0, 'appointments': 0, 'visits': 0};

          final total = (m['new'] ?? 0) +
              (m['appointments'] ?? 0) +
              (m['visits'] ?? 0);

          final sections = [
            _sec(m['new'] ?? 0, theme.colorScheme.primary),
            _sec(m['appointments'] ?? 0, theme.colorScheme.tertiary),
            _sec(m['visits'] ?? 0, theme.colorScheme.secondary),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SearchBox(
                          onChanged: (s) {}, hint: t.search),
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<Period>(
                      segments: [
                        ButtonSegment(value: Period.weekly, label: Text(t.weekly)),
                        ButtonSegment(value: Period.monthly, label: Text(t.monthly)),
                        ButtonSegment(value: Period.yearly, label: Text(t.yearly)),
                      ],
                      selected: {p},
                      onSelectionChanged: (s) => setState(() => p = s.first),
                    )
                  ],
                ),

                const SizedBox(height: 20),

                Card(
                  color: theme.colorScheme.surface,
                  shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          t.hospitalOverview,
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          height: 220,
                          child: total == 0
                              ? Center(child: Text(t.noData))
                              : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 48,
                              sections: sections,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _legend(context,
                            color: theme.colorScheme.primary,
                            text: t.newRegister,
                            value: m['new'] ?? 0),

                        _legend(context,
                            color: theme.colorScheme.tertiary,
                            text: t.appointments,
                            value: m['appointments'] ?? 0),

                        _legend(context,
                            color: theme.colorScheme.secondary,
                            text: t.visits,
                            value: m['visits'] ?? 0),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _bigButton(context, t.doctorReports,
                    icon: Icons.medical_information,
                    onTap: () => Navigator.pushNamed(
                        context, HospitalDoctorReportsScreen.route)),

                const SizedBox(height: 12),

              ],
            ),
          );
        },
      ),
    );
  }

  PieChartSectionData _sec(int v, Color c) {
    return PieChartSectionData(
      value: (v <= 0 ? 1 : v).toDouble(),
      color: c,
      radius: 45,
      title: v.toString(),
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _legend(BuildContext context,
      {required Color color, required String text, required int value}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),

          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          Text(value.toString(),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _bigButton(BuildContext ctx, String title,
      {required IconData icon, VoidCallback? onTap}) {
    final theme = Theme.of(ctx);

    return Card(
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onPrimary),
        title: Text(title,
            style: TextStyle(
                color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onPrimary),
        onTap: onTap,
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.onChanged, required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.mic_none),
        hintText: hint,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }
}
