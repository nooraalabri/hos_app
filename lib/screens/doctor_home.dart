import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'doctor/my_shifts_screen.dart';
import 'doctor/reviews.dart';
import 'doctor/weekly_shifts_screen.dart';
import 'settings_screen.dart';

class DoctorHome extends StatefulWidget {
  final String doctorId;
  const DoctorHome({super.key, required this.doctorId});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  Map<String, dynamic>? _doctor;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.doctorId)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      setState(() => _doctor = doc.data());
    }
  }

  Future<void> _editDoctor() async {
    if (_doctor == null) return;

    final nameCtrl = TextEditingController(text: _doctor?['name'] ?? '');
    final emailCtrl = TextEditingController(text: _doctor?['email'] ?? '');
    final specializationCtrl =
    TextEditingController(text: _doctor?['specialization'] ?? '');
    final bioCtrl = TextEditingController(text: _doctor?['bio'] ?? '');

    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(t.editProfile),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: t.name)),
              TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(labelText: t.email)),
              TextField(
                  controller: specializationCtrl,
                  decoration: InputDecoration(labelText: t.specialization)),
              TextField(
                  controller: bioCtrl,
                  decoration: InputDecoration(labelText: t.bio)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.doctorId)
                  .set({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'specialization': specializationCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              if (!mounted) return;

              Navigator.pop(context);
              _loadProfile();
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.doctorProfile,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _editDoctor,
            icon: Icon(Icons.edit, color: theme.colorScheme.onPrimary),
          ),
        ],
      ),
      drawer: _DoctorDrawer(doctorId: widget.doctorId),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _doctor == null
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      )
          : _DoctorProfileBody(
        data: _doctor!,
        doctorId: widget.doctorId,
      ),
    );
  }
}

class _DoctorProfileBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final String doctorId;

  const _DoctorProfileBody({required this.data, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final status = data['approved'] == true ? t.approved : t.pending;
    final statusColor =
    data['approved'] == true ? Colors.green : Colors.orange;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: theme.cardColor,
          shadowColor: theme.shadowColor.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  title: Text(data['name'] ?? t.name,
                      style: theme.textTheme.titleMedium),
                  subtitle: Text(data['email'] ?? '',
                      style: theme.textTheme.bodyMedium),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ),
                const SizedBox(height: 12),
                _kv(t.specialization, data['specialization'] ?? '—', theme),
                _kv(t.bio, data['bio'] ?? '—', theme),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showDetails(context, data),
                    child: Text(t.details),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          t.quickAccess,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),

        _linkTile(
          context,
          icon: Icons.calendar_today,
          title: t.myShifts,
          screen: MyShiftsScreen(doctorId: doctorId),
        ),
        _linkTile(
          context,
          icon: Icons.date_range,
          title: t.weeklyShifts,
          screen: ShiftsOverviewScreen(doctorId: doctorId),
        ),
        _linkTile(
          context,
          icon: Icons.reviews,
          title: t.reviews,
          screen: ReviewsScreen(doctorId: doctorId),
        ),
      ],
    );
  }

  Widget _kv(String k, String v, ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            k,
            style: theme.textTheme.titleSmall!
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(v, style: theme.textTheme.bodyMedium),
        ),
      ],
    ),
  );

  void _showDetails(BuildContext context, Map<String, dynamic> d) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              t.doctorDetails,
              style: theme.textTheme.titleLarge!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _kv(t.name, d['name'] ?? '', theme),
            _kv(t.email, d['email'] ?? '', theme),
            _kv(t.specialization, d['specialization'] ?? '', theme),
            _kv(t.bio, d['bio'] ?? '—', theme),
            _kv(
              t.status,
              d['approved'] == true ? t.approved : t.pending,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkTile(BuildContext context,
      {required IconData icon,
        required String title,
        required Widget screen}) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: theme.iconTheme.color,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}

class _DoctorDrawer extends StatelessWidget {
  final String doctorId;
  const _DoctorDrawer({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                t.doctorMenu,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          _drawerTile(context, Icons.home, t.home, () {
            Navigator.pop(context);
          }),
          _drawerTile(context, Icons.calendar_today, t.myShifts, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MyShiftsScreen(doctorId: doctorId)),
            );
          }),
          _drawerTile(context, Icons.date_range, t.weeklyShifts, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ShiftsOverviewScreen(doctorId: doctorId)),
            );
          }),
          _drawerTile(context, Icons.reviews, t.reviews, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ReviewsScreen(doctorId: doctorId)),
            );
          }),
          _drawerTile(context, Icons.settings, t.settings, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(t.logout, style: theme.textTheme.bodyMedium),
            onTap: () => AuthService.logoutAndGoWelcome(context),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title, style: theme.textTheme.bodyMedium),
      onTap: onTap,
    );
  }
}
