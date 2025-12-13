import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../routes.dart';
import '../widgets/app_logo.dart';

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

  final RegExp _passRe = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  // ===== Validators =====
  String? _validatePassword(String? v, AppLocalizations t) {
    if (v == null || v.isEmpty) return t.passwordRequired;
    if (!_passRe.hasMatch(v)) return t.passwordRules;
    return null;
  }

  String? _validateConfirm(String? v, AppLocalizations t) {
    if (v == null || v.isEmpty) return t.confirmPasswordRequired;
    if (v != _p1.text) return t.passwordsNotMatch;
    return null;
  }

  // ===== Submit =====
  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
      err = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      // المحاولة رقم 1: تحديث كلمة المرور مباشرة
      if (user != null) {
        try {
          await user.updatePassword(_p1.text.trim());

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.passwordUpdated)),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
                (_) => false,
          );
          return;
        } on FirebaseAuthException catch (e) {
          if (e.code != 'requires-recent-login') {
            setState(() => err = e.message ?? e.code);
            return;
          }
        }
      }

      // المحاولة رقم 2: إرسال رابط إعادة التعيين
      if (email.isNotEmpty) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.emailResetLink)),
        );
      } else {
        setState(() => err = t.noEmailFound);
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (_) => false,
        );
      }

    } catch (e) {
      if (mounted) setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(size: 90),
                const SizedBox(height: 10),

                Text(
                  t.resetPasswordTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // New Password
                TextFormField(
                  controller: _p1,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t.newPassword,
                    hintText: t.enterNewPassword,
                  ),
                  validator: (v) => _validatePassword(v, t),
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextFormField(
                  controller: _p2,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t.confirmNewPassword,
                    hintText: t.reenterNewPassword,
                  ),
                  validator: (v) => _validateConfirm(v, t),
                ),

                const SizedBox(height: 8),
                Text(
                  t.passwordHintText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha:.6),
                  ),
                ),

                const SizedBox(height: 14),

                if (err != null)
                  Text(
                    err!,
                    style: TextStyle(color: cs.error),
                  ),

                const SizedBox(height: 14),

                // BUTTON
                ElevatedButton(
                  onPressed: saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(t.update),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
