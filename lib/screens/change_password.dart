import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_logo.dart';
import '../widgets/password_input.dart';
import '../routes.dart';


class ChangePasswordScreen extends StatefulWidget {
  static const route = '/change-password';
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new1 = TextEditingController();
  final _new2 = TextEditingController();

  bool _loading = false;
  String? _error; // خطأ عام تحت الزر
  String? _currentErr; // خطأ خاص بحقل current password

  final RegExp _passwordRe = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _new1.dispose();
    _new2.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (!_passwordRe.hasMatch(v)) {
      return 'Must have 8+ chars, upper, lower, number & symbol';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _currentErr = null;
    });

    try {
      // 1️⃣ التحقق من إدخال كلمة المرور القديمة
      if (_current.text.trim().isEmpty) {
        setState(() {
          _currentErr = 'Enter your current password';
        });
        return;
      }

      // 2️⃣ التحقق من صحة كلمة المرور القديمة عبر Firebase
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _current.text.trim(),
      );

      try {
        await user.reauthenticateWithCredential(cred);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          setState(() {
            _currentErr = 'Current password is incorrect';
          });
          return;
        } else {
          setState(() {
            _error = e.message ?? e.code;
          });
          return;
        }
      }

      // 3️⃣ التحقق أن الباسورد الجديد مو نفسه القديم
      if (_new1.text.trim() == _current.text.trim()) {
        setState(() {
          _error = 'New password must be different from current password';
        });
        return;
      }

      // 4️⃣ التحقق من قوة الباسورد الجديد وتطابقه مع التأكيد
      if (!_form.currentState!.validate()) return;

      if (_new1.text != _new2.text) {
        setState(() {
          _error = 'Passwords do not match';
        });
        return;
      }

      // 5️⃣ تحديث كلمة المرور الجديدة
      await user.updatePassword(_new1.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  const AppLogo(),
                  const SizedBox(height: 10),
                  Text('Change Password',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 20),

                  // 🟣 حقل كلمة المرور الحالية
                  TextFormField(
                    controller: _current,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _currentErr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🟣 حقل الباسورد الجديد
                  PasswordInput(
                    controller: _new1,
                    label: 'New Password',
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: 12),

                  // 🟣 حقل تأكيد الباسورد الجديد
                  PasswordInput(
                    controller: _new2,
                    label: 'Confirm New Password',
                    validator: (v) =>
                    v != _new1.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 16),

                  // 🔴 رسالة خطأ عامة
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // 🔘 زر الحفظ (نفس زر اللوج إن)
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save'),
                    ),
                  ),

                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
