import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../widgets/app_logo.dart';
import '../widgets/app_input.dart';
import '../widgets/password_input.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';
import '../routes.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _civil = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _loading = false;
  String? _error;

  final RegExp _passRe = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _civil.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final first = DateTime(now.year - 100, 1, 1);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      _dob.text =
      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = AppUser(
        uid: 'temp',
        email: _email.text.trim(),
        role: 'patient',
        name: _name.text.trim(),
      );

      final cred = await AuthService.registerWithEmail(
        email: _email.text.trim(),
        password: _pass.text,
        profile: profile,
      );

      final uid = cred.user?.uid;
      if (uid == null) throw Exception('Registration failed: UID is null.');

      await FS.createUser(uid, {
        'dob': _dob.text.trim(),
        'civilNumber': _civil.text.trim(),
        'role': 'patient',
      });

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.patientHome,
            (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
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
                  t.register,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 14),

                // === Name ===
                AppInput(
                  controller: _name,
                  label: t.myName,
                  validator: (v) => (v == null || v.isEmpty) ? t.required : null,
                ),

                const SizedBox(height: 12),

                // === DOB ===
                GestureDetector(
                  onTap: _pickDob,
                  child: AbsorbPointer(
                    child: AppInput(
                      controller: _dob,
                      label: t.dateOfBirth,
                      hint: t.dobHint,
                      validator: (v) =>
                      (v == null || v.isEmpty) ? t.required : null,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // === Civil Number ===
                AppInput(
                  controller: _civil,
                  label: t.civilNumber,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return t.required;
                    if (!RegExp(r'^\d{8}$').hasMatch(v)) {
                      return t.civilMustBe8;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // === Email ===
                AppInput(
                  controller: _email,
                  label: t.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? t.validEmailRequired : null,
                ),

                const SizedBox(height: 12),

                // === Password ===
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

                // === Confirm Password ===
                PasswordInput(
                  controller: _pass2,
                  label: t.confirmPassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return t.confirmPasswordRequired;
                    if (v != _pass.text) return t.passwordsNotMatch;
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : Text(t.signUp),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(t.alreadyHaveAccount),
                      InkWell(
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                                (_) => false,
                          );
                        },
                        child: Text(
                          t.login,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
