import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes.dart';
import '../widgets/app_logo.dart';
import '../l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();

  String email = '';
  bool saving = false;
  String? err;

  // Regex: حرف صغير + حرف كبير + رقم + رمز خاص + طول ≥ 8
  final RegExp _passRe = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$'
  );

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (!_passRe.hasMatch(v)) {
      return 'Min 8 chars incl. upper, lower, number & special';
    }
    return null;
    // لو تبي نص عربي:
    // return 'الحد الأدنى 8 أحرف وتتضمن حرف كبير وصغير ورقم ورمز خاص';
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please re-enter password';
    if (v != _p1.text) return 'Passwords do not match';
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // نستقبل الإيميل من EnterCodeScreen
    email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      err = null;
      saving = true;
    });

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user != null) {
        try {
          await user.updatePassword(_p1.text.trim());
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (_) => false);
          return;
        } on FirebaseAuthException catch (e) {
          // يتطلب recent login
          if (e.code != 'requires-recent-login') {
            setState(() => err = e.message ?? e.code);
            return;
          }
          // وإلا نكمل بإرسال رابط رسمي ثم نرجع للّوج إن
        }
      }

      // لا يوجد مستخدم أو يتطلب recent login → نرسل رابط رسمي
      if (email.isNotEmpty) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We emailed you a reset link. Please check your inbox.'),
          ),
        );
      } else {
        setState(() => err = 'No email found for reset.');
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (_) => false);
      }
    } catch (e) {
      if (mounted) setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(),
                Text(
                  AppLocalizations.of(context)?.reset_password ?? 'Reset\npassword',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _p1,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.password ?? 'New password',
                    hintText: 'Enter new password',
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _p2,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.confirm_password ?? 'Confirm new password',
                    hintText: 'Re-enter new password',
                  ),
                  validator: _validateConfirm,
                ),

                const SizedBox(height: 8),
                // قواعد الباسورد (تذكير للمستخدم)
                const Text(
                  'Password must have at least 8 characters, including upper & lower letters, a number, and a special character.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),

                const SizedBox(height: 12),
                if (err != null)
                  Text(err!, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: saving ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                    child: saving
                        ? const CircularProgressIndicator()
                        : Text(AppLocalizations.of(context)?.update ?? 'Update'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
