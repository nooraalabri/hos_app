import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_input.dart';
import '../widgets/password_input.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';
import '../routes.dart';
import '../services/email_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key});

  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _spec = TextEditingController();

  String? hospitalId;
  List<Map<String, dynamic>> hospitals = [];

  bool _fetchingHospitals = true;
  bool _submitting = false;
  String? _error;

  final RegExp _passRe = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      final list = await FS.listHospitals(onlyApproved: true);
      if (!mounted) return;

      setState(() {
        hospitals = list;
        _fetchingHospitals = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load hospitals: $e';
        _fetchingHospitals = false;
      });
    }
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

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
        'approved': false,
      });

      try {
        final selectedHospital =
        hospitals.firstWhere((h) => h['id'] == hospitalId);

        final hospEmail = selectedHospital['email']?.toString();
        if (hospEmail != null && hospEmail.isNotEmpty) {
          await _notifyHospAdmin(
            doctorName: _name.text.trim(),
            hospAdminEmail: hospEmail,
            hospitalId: hospitalId!,
          );
        }
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.pendingApproval,
            (_) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _notifyHospAdmin({
    required String doctorName,
    required String hospAdminEmail,
    required String hospitalId,
  }) async {
    final apiUrl = '${EmailApiConfig.baseUrl}/notify-hospadmin';

    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorName': doctorName,
          'hospAdminEmail': hospAdminEmail,
          'hospitalId': hospitalId,
        }),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_fetchingHospitals) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final noHospitals = hospitals.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(size: 90),

                Text(
                  t.registerDoctor,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Email
                AppInput(
                  controller: _email,
                  label: t.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? t.validEmailRequired : null,
                ),
                const SizedBox(height: 12),

                // Hospital dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: t.hospital),
                  value: hospitalId,
                  items: hospitals.map((h) {
                    return DropdownMenuItem<String>(
                      value: h['id'].toString(),
                      child: Text(h['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged:
                  noHospitals ? null : (v) => setState(() => hospitalId = v),
                  validator: (v) => v == null ? t.selectHospital : null,
                ),
                const SizedBox(height: 12),

                // Password
                PasswordInput(
                  controller: _pass,
                  label: t.password,
                  validator: (v) {
                    if (v == null || v.isEmpty) return t.passwordRequired;
                    if (!_passRe.hasMatch(v)) return t.passwordRules;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Confirm Password
                PasswordInput(
                  controller: _pass2,
                  label: t.confirmPassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return t.confirmPasswordRequired;
                    if (v != _pass.text) return t.passwordsDoNotMatch;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Full name
                AppInput(
                  controller: _name,
                  label: t.fullName,
                  validator: (v) =>
                  (v == null || v.isEmpty) ? t.required : null,
                ),
                const SizedBox(height: 12),

                // Specialization
                AppInput(
                  controller: _spec,
                  label: t.specialization,
                  validator: (v) =>
                  (v == null || v.isEmpty) ? t.required : null,
                ),
                const SizedBox(height: 18),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),

                ElevatedButton(
                  onPressed: (_submitting || noHospitals) ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    child: _submitting
                        ? const CircularProgressIndicator()
                        : Text(t.signUp),
                  ),
                ),

                if (noHospitals) ...[
                  const SizedBox(height: 12),
                  Text(
                    t.noHospitalsFound,
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                          (_) => false,
                    ),
                    child: Text(
                      t.alreadyHaveAccount,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
