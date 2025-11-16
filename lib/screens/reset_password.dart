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
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$');

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

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

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
            SnackBar(content: Text(t.passwordUpdated)),
          );

          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (_) => false);
          return;

        } on FirebaseAuthException catch (e) {
          if (e.code != 'requires-recent-login') {
            setState(() => err = e.message ?? e.code);
            return;
          }
        }
      }

      // No user or recent login required → send reset link
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
    final t = AppLocalizations.of(context)!;

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
                  t.resetPasswordTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _p1,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t.newPassword,
                    hintText: t.enterNewPassword,
                  ),
                  validator: (v) => _validatePassword(v, t),
                ),

                const SizedBox(height: 12),

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
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),

                const SizedBox(height: 12),

                if (err != null)
                  Text(err!, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: saving ? null : _submit,
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                    child: saving
                        ? const CircularProgressIndicator()
                        : Text(t.update),
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
