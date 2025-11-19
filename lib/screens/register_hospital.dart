import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../widgets/app_input.dart';
import '../widgets/password_input.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notify_service.dart';
import '../models/app_user.dart';
import '../routes.dart';
import 'map_picker_screen.dart';

class RegisterHospitalScreen extends StatefulWidget {
  const RegisterHospitalScreen({super.key});

  @override
  State<RegisterHospitalScreen> createState() => _RegisterHospitalScreenState();
}

class _RegisterHospitalScreenState extends State<RegisterHospitalScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  final _licenseNo = TextEditingController();
  final _crNumber = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _website = TextEditingController();

  double? _lat;
  double? _lng;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    _licenseNo.dispose();
    _crNumber.dispose();
    _phone.dispose();
    _location.dispose();
    _website.dispose();
    super.dispose();
  }

  // ================= VALIDATION =================

  bool _isStrong(String v) =>
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^\w\s]).{8,}$').hasMatch(v);

  bool _validHospitalName(String v) =>
      RegExp(r'^[a-zA-Z0-9\u0621-\u064A ]{3,}$').hasMatch(v);

  bool _validLicense(String v) =>
      RegExp(r'^\d{5,8}$').hasMatch(v);

  bool _validCR(String v) =>
      RegExp(r'^\d{8}$').hasMatch(v);

  bool _validOmanNumber(String v) =>
      RegExp(r'^[279]\d{7}$').hasMatch(v);

  bool _validWebsite(String v) =>
      v.isEmpty || RegExp(r'^https?:\/\/').hasMatch(v);

  // ================= SUBMIT =================

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

    if (!_form.currentState!.validate()) return;

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${t.addressLocation} ${t.required}")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1 — Create Account
      final profile = AppUser(
        uid: 'temp',
        email: _email.text.trim(),
        role: 'hospitaladmin',
        name: _name.text.trim(),
      );

      final cred = await AuthService.registerWithEmail(
        email: _email.text.trim(),
        password: _pass.text,
        profile: profile,
      );

      final uid = cred.user!.uid;

      // 2 — Save Hospital
      await FS.createHospital(
        name: _name.text.trim(),
        email: _email.text.trim(),
        uid: uid,
        data: {
          'licenseNumber': _licenseNo.text.trim(),
          'crNumber': _crNumber.text.trim(),
          'phone': _phone.text.trim(),
          'location': _location.text.trim(),
          'lat': _lat,
          'lng': _lng,
          'website': _website.text.trim(),
          'approved': false,
          'createdAt': DateTime.now(),
        },
      );

      // 3 — Save user
      await FS.createUser(uid, {
        'role': 'hospitaladmin',
        'hospitalId': uid,
        'approved': false,
      });

      // 4 — Notify Head Admin
      try {
        await NotifyService.notifyHeadAdmin(_name.text.trim());
      } catch (_) {}

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.pendingApproval,
            (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Image.asset('assets/logo.png', height: 110)),
                const SizedBox(height: 10),

                Text(
                  t.registerHospital,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 18),

                // ================= INPUTS =================

                AppInput(
                  controller: _name,
                  label: t.hospitalName,
                  hint: t.enterOfficialHospitalName,
                  validator: (v) => v != null && _validHospitalName(v)
                      ? null
                      : t.required,
                ),
                const SizedBox(height: 12),

                AppInput(
                  controller: _licenseNo,
                  label: t.licenseNumber,
                  validator: (v) =>
                  v != null && _validLicense(v) ? null : t.licenseNumber,
                ),
                const SizedBox(height: 12),

                AppInput(
                  controller: _crNumber,
                  label: t.crNumber,
                  validator: (v) =>
                  v != null && _validCR(v) ? null : t.crNumber,
                ),
                const SizedBox(height: 12),

                AppInput(
                  controller: _phone,
                  label: t.phoneNumber,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                  v != null && _validOmanNumber(v)
                      ? null
                      : t.enterValidNumber,
                ),
                const SizedBox(height: 12),

                AppInput(
                  controller: _email,
                  label: t.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v != null && v.contains('@'))
                      ? null
                      : t.validEmailRequired,
                ),
                const SizedBox(height: 12),

                PasswordInput(
                  controller: _pass,
                  label: t.password,
                  validator: (v) =>
                  _isStrong(v ?? '') ? null : t.passwordRulesFull,
                ),
                const SizedBox(height: 12),

                PasswordInput(
                  controller: _confirmPass,
                  label: t.confirmPassword,
                  validator: (v) =>
                  v == _pass.text ? null : t.passwordsDoNotMatch,
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapPickerScreen(),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _location.text = result["address"];
                        _lat = result["lat"];
                        _lng = result["lng"];
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: AppInput(
                      controller: _location,
                      label: t.addressLocation,
                      hint: t.pickFromMap,
                      validator: (v) =>
                      v != null && v.isNotEmpty ? null : t.required,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                AppInput(
                  controller: _website,
                  label: t.websiteOptional,
                  hint: "https://example.com",
                  validator: (v) =>
                  _validWebsite(v ?? '') ? null : "Invalid URL",
                ),

                const SizedBox(height: 16),

                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(t.signUp),
                  ),
                ),

                const SizedBox(height: 18),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.alreadyHaveAccount),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(
                                context, AppRoutes.login),
                        child: Text(t.login),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
