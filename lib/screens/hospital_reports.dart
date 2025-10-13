import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_drawer.dart';

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
    FS.hospitalForAdmin(uid).then((d) => setState(() => hospId = d?['id']));
  }

  @override
  Widget build(BuildContext context) {
    final periodKey = switch (p) {
      Period.weekly => 'weekly',
      Period.monthly => 'monthly',
      Period.yearly => 'yearly',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Reports')),
      drawer: const AdminDrawer(),
      body: hospId == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, int>>(
        future: FS.statsForHospital(hospId!, periodKey),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final m = snap.data ?? const {
            'new': 0,
            'appointments': 0,
            'visits': 0
          };
          final total = (m['new'] ?? 0) +
              (m['appointments'] ?? 0) +
              (m['visits'] ?? 0);

          final sections = [
            _sec(m['new'] ?? 0, Colors.purple),
            _sec(m['appointments'] ?? 0, Colors.teal),
            _sec(m['visits'] ?? 0, Colors.blueGrey),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === Search + Period Selector ===
                Row(
                  children: [
                    Expanded(child: _SearchBox(onChanged: (s) {})),
                    const SizedBox(width: 12),
                    SegmentedButton<Period>(
                      segments: const [
                        ButtonSegment(
                            value: Period.weekly, label: Text("Weekly")),
                        ButtonSegment(
                            value: Period.monthly, label: Text("Monthly")),
                        ButtonSegment(
                            value: Period.yearly, label: Text("Yearly")),
                      ],
                      selected: {p},
                      onSelectionChanged: (s) =>
                          setState(() => p = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // === Pie Chart Card ===
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Hospital Overview",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 220,
                          child: total == 0
                              ? const Center(
                              child: Text('No data available'))
                              : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 48,
                              sections: sections,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _legend(
                            color: Colors.purple,
                            text: 'New register',
                            value: m['new'] ?? 0),
                        _legend(
                            color: Colors.teal,
                            text: 'Appointments',
                            value: m['appointments'] ?? 0),
                        _legend(
                            color: Colors.blueGrey,
                            text: 'Visits',
                            value: m['visits'] ?? 0),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // === Buttons ===
                _bigButton(
                  context,
                  'Doctor Reports',
                  icon: Icons.medical_information,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Doctor reports coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _bigButton(
                  context,
                  'Patient Reports',
                  icon: Icons.people,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Patient reports coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 30),
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
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _legend(
      {required Color color, required String text, required int value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          Text(value.toString(),
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _bigButton(BuildContext ctx, String title,
      {IconData icon = Icons.arrow_forward_ios, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF2D515C),
          borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: onTap,
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.mic_none),
        hintText: 'Search',
        filled: true,
        fillColor: Colors.black.withOpacity(.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }
}
