import 'package:flutter/material.dart';
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

  // تحقق من قوة الباسورد: صغير + كبير + رقم + رمز + طول ≥ 8
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
      "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // إنشاء الحساب
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

      // تخزين بيانات إضافية في Firestore
      await FS.createUser(uid, {
        'dob': _dob.text.trim(),
        'civilNumber': _civil.text.trim(),
        'role': 'patient',
      });

      if (!mounted) return;

      // ✅ بعد التسجيل يذهب مباشرة إلى صفحة المريض الجديدة
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
                  'Register',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                // الاسم
                AppInput(
                  controller: _name,
                  label: 'My Name',
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // تاريخ الميلاد
                GestureDetector(
                  onTap: _pickDob,
                  child: AbsorbPointer(
                    child: AppInput(
                      controller: _dob,
                      label: 'Date of Birth',
                      hint: 'YYYY-MM-DD',
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // رقم البطاقة المدنية (8 أرقام بالضبط)
                AppInput(
                  controller: _civil,
                  label: 'Civil Number',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{8}$').hasMatch(v)) {
                      return 'Must be exactly 8 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // الإيميل
                AppInput(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Valid email required'
                      : null,
                ),
                const SizedBox(height: 12),

                // الباسورد
                PasswordInput(
                  controller: _pass,
                  label: 'Password',
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password is required';
                    }
                    if (!_passRe.hasMatch(v)) {
                      return 'Min 8 incl. upper, lower, number & special';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // تأكيد الباسورد
                PasswordInput(
                  controller: _pass2,
                  label: 'Confirm Password',
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (v != _pass.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Sign Up'),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      InkWell(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                              (_) => false,
                        ),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
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
