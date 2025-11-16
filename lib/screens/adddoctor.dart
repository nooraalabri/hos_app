import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/email_api.dart';
import '../models/app_user.dart';
import '../routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../l10n/app_localizations.dart';

class AddDoctorByAdminScreen extends StatefulWidget {
  const AddDoctorByAdminScreen({super.key});

  @override
  State<AddDoctorByAdminScreen> createState() => _AddDoctorByAdminScreenState();
}

class _AddDoctorByAdminScreenState extends State<AddDoctorByAdminScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _spec = TextEditingController();

  bool _submitting = false;
  String? _error;
  String? hospitalId;
  String? hospitalName;

  final RegExp _passRe = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
  }

  Future<void> _loadHospitalInfo() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final hosp = await FS.hospitalForAdmin(uid);
    setState(() {
      hospitalId = hosp?['id'];
      hospitalName = hosp?['name'] ?? 'My Hospital';
    });
  }

  Future<void> _sendEmailToDoctor(String email, String password) async {
    final apiUrl = '${EmailApiConfig.baseUrl}/notify-doctor';
    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorEmail': email,
          'doctorPassword': password,
          'hospitalName': hospitalName ?? '',
        }),
      );

      if (res.statusCode == 200) {
        debugPrint('Doctor email sent');
      } else {
        debugPrint('Email failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error sending doctor email: $e');
    }
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;

    if (!_form.currentState!.validate() || hospitalId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final profile = AppUser(
        uid: 'temp',
        email: _email.text.trim(),
        role: 'doctor',
        name: _name.text.trim(),
        hospitalId: hospitalId,
        specialization: _spec.text.trim(),
      );

      final cred = await AuthService.registerWithEmail(
        email: _email.text.trim(),
        password: _pass.text,
        profile: profile,
      );

      final uid = cred.user!.uid;

      await FS.createUser(uid, {
        'role': 'doctor',
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'hospitalId': hospitalId,
        'specialization': _spec.text.trim(),
        'approved': true,
      });

      await _sendEmailToDoctor(_email.text.trim(), _pass.text);

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.hospitalAdminHome,
            (route) => false,
        arguments: {'successMessage': loc.shift_added},
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (hospitalId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D515C),
        title: Text('${loc.add_shift} - $hospitalName'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: loc.back,
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.hospitalAdminHome,
                  (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: loc.email),
                validator: (v) => (v == null || !v.contains('@'))
                    ? loc.invalid_email
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: true,
                decoration: InputDecoration(labelText: loc.password),
                validator: (v) {
                  if (v == null || v.isEmpty) return loc.required_field;
                  if (!_passRe.hasMatch(v)) {
                    return loc.weak_password;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: loc.fullname),
                validator: (v) =>
                (v == null || v.isEmpty) ? loc.required_field : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _spec,
                decoration: InputDecoration(labelText: loc.specialization),
                validator: (v) =>
                (v == null || v.isEmpty) ? loc.required_field : null,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D515C),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  loc.add_shift,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
