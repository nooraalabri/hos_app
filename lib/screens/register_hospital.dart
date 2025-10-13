import 'package:flutter/material.dart';

import '../widgets/app_input.dart';
import '../widgets/password_input.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notify_service.dart';
import '../models/app_user.dart';
import '../routes.dart';

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
  final _location = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _location.dispose();
    super.dispose();
  }

  // ✅ Password strength check
  bool _isStrong(String v) {
    if (v.length < 8) return false;
    final rUpper = RegExp(r'[A-Z]');
    final rLower = RegExp(r'[a-z]');
    final rNum = RegExp(r'\d');
    final rSym = RegExp(r'[^\w\s]');
    return rUpper.hasMatch(v) &&
        rLower.hasMatch(v) &&
        rNum.hasMatch(v) &&
        rSym.hasMatch(v);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) إنشاء حساب hospitaladmin
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

      // 2) إنشاء مستشفى جديد pending
      final hospitalId = await FS.createHospital(
        name: _name.text.trim(),
        email: _email.text.trim(),
        uid: uid,
      );

      // 3) إنشاء user مربوط بالمستشفى + approved=false
      await FS.createUser(uid, {
        'role': 'hospitaladmin',
        'hospitalId': uid, // نفس uid
        'approved': false,
      });


      // 4) تحديث موقع المستشفى إذا متوفر
      if (_location.text.trim().isNotEmpty) {
        await FS.updateHospitalLocation(
          uid,
          address: _location.text.trim(),
          city: null,
          country: null,
        );
      }

      // 5) تنبيه الهيد أدمن
      try {
        await NotifyService.notifyHeadAdmin(_name.text.trim());
        debugPrint("✅ HeadAdmin notified about hospital request");
      } catch (e) {
        debugPrint("⚠️ NotifyService error notifyHeadAdmin: $e");
      }

      if (!mounted) return;

      // ✅ تحويل لصفحة Pending Approval
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.pendingApproval, // 👈 لازم تعرفي هذا في routes
            (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Register Hospital',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),

                AppInput(
                  controller: _name,
                  label: 'Hospital',
                  hint: 'Enter hospital name',
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                AppInput(
                  controller: _email,
                  label: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),

                PasswordInput(
                  controller: _pass,
                  label: 'Password',
                  validator: (v) => (v != null && _isStrong(v))
                      ? null
                      : 'Min 8, upper/lower/number/symbol',
                ),
                const SizedBox(height: 12),

                AppInput(
                  controller: _location,
                  label: 'Location',
                  hint: 'Enter hospital address or location',
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: 18),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Sign up'),
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
