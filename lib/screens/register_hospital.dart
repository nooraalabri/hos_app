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
  final _confirmPass = TextEditingController();
  final _location = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    _location.dispose();
    super.dispose();
  }

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
      // 🔹 إنشاء حساب hospitaladmin
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

      // 🏥 إنشاء مستشفى جديد pending
      await FS.createHospital(
        name: _name.text.trim(),
        email: _email.text.trim(),
        uid: uid,
      );

      // 👤 إنشاء user مربوط بالمستشفى + approved=false
      await FS.createUser(uid, {
        'role': 'hospitaladmin',
        'hospitalId': uid,
        'approved': false,
      });

      // 📍 تحديث موقع المستشفى إذا متوفر
      if (_location.text.trim().isNotEmpty) {
        await FS.updateHospitalLocation(
          uid,
          address: _location.text.trim(),
          city: null,
          country: null,
        );
      }

      // 📩 تنبيه الهيد أدمن عبر NotifyService
      try {
        await NotifyService.notifyHeadAdmin(_name.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notification sent to Head Admin successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        debugPrint("✅ HeadAdmin notified about hospital request");
      } catch (e) {
        debugPrint("⚠️ NotifyService error notifyHeadAdmin: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Failed to notify Head Admin: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (!mounted) return;

      // ⏳ تحويل المستخدم لصفحة Pending Approval
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.pendingApproval,
            (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                Center(
                  child: Image.asset('assets/logo.png', height: 120),
                ),
                const SizedBox(height: 10),

                Text(
                  'Register Hospital',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                AppInput(
                  controller: _name,
                  label: 'Hospital Name',
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
                      : 'Min 8 chars, must include upper/lower/number/symbol',
                ),
                const SizedBox(height: 12),

                PasswordInput(
                  controller: _confirmPass,
                  label: 'Confirm Password',
                  validator: (v) =>
                  (v == _pass.text) ? null : 'Passwords do not match',
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign up'),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppRoutes.login),
                      child: const Text('Login'),
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
