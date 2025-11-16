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

  bool _isStrong(String v) {
    if (v.length < 8) return false;
    return RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^\w\s]).+$').hasMatch(v);
  }

  bool _isHospitalNameValid(String v) {
    return v.trim().length >= 3 &&
        RegExp(r'^[a-zA-Z0-9\u0621-\u064A ]+$').hasMatch(v);
  }

  bool _isMOHLicenseValid(String v) {
    return RegExp(r'^\d{5,8}$').hasMatch(v);
  }

  bool _isCRValid(String v) {
    return RegExp(r'^\d{8}$').hasMatch(v);
  }

  bool _isOmanPhone(String v) {
    return RegExp(r'^[279]\d{7}$').hasMatch(v);
  }

  bool _isWebsiteValid(String v) {
    return v.isEmpty || RegExp(r'^(https?:\/\/)').hasMatch(v);
  }

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
      /// 1️⃣ إنشاء الحساب في Firebase Auth
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

      /// 2️⃣ حفظ بيانات المستشفى
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

      /// 3️⃣ حفظ بيانات المستخدم
      await FS.createUser(uid, {
        'role': 'hospitaladmin',
        'hospitalId': uid,
        'approved': false,
      });

      /// 4️⃣ إشعار الهيد أدمن
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

                // NAME
                AppInput(
                  controller: _name,
                  label: t.hospitalName,
                  hint: t.enterOfficialHospitalName,
                  validator: (v) =>
                  (v == null || !_isHospitalNameValid(v)) ? t.required : null,
                ),
                const SizedBox(height: 10),

                // LICENSE NO
                AppInput(
                  controller: _licenseNo,
                  label: t.licenseNumber,
                  hint: t.mohLicenseNumber,
                  validator: (v) =>
                  (v == null || !_isMOHLicenseValid(v)) ? t.licenseNumber : null,
                ),
                const SizedBox(height: 10),

                // CR NUMBER
                AppInput(
                  controller: _crNumber,
                  label: t.crNumber,
                  hint: t.enterCrNumber,
                  validator: (v) =>
                  (v == null || !_isCRValid(v)) ? t.crNumber : null,
                ),
                const SizedBox(height: 10),

                // PHONE
                AppInput(
                  controller: _phone,
                  label: t.phoneNumber,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                  (v == null || !_isOmanPhone(v)) ? t.enterValidNumber : null,
                ),
                const SizedBox(height: 10),

                // EMAIL
                AppInput(
                  controller: _email,
                  label: t.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? t.validEmailRequired : null,
                ),
                const SizedBox(height: 10),

                // PASSWORD
                PasswordInput(
                  controller: _pass,
                  label: t.password,
                  validator: (v) =>
                  (v != null && _isStrong(v)) ? null : t.passwordRulesFull,
                ),
                const SizedBox(height: 10),

                // CONFIRM PASSWORD
                PasswordInput(
                  controller: _confirmPass,
                  label: t.confirmPassword,
                  validator: (v) =>
                  (v == _pass.text) ? null : t.passwordsDoNotMatch,
                ),
                const SizedBox(height: 10),

                // LOCATION
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
                      (v == null || v.isEmpty) ? t.required : null,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // WEBSITE
                AppInput(
                  controller: _website,
                  label: t.websiteOptional,
                  hint: 'https://example.com',
                  validator: (v) =>
                  _isWebsiteValid(v ?? '') ? null : "Invalid URL",
                ),

                const SizedBox(height: 18),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.alreadyHaveAccount),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, AppRoutes.login),
                      child: Text(t.login),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
