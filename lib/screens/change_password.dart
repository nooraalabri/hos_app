import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
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
  String? _error;
  String? _currentErr;

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

  String? _validateNewPassword(String? v, AppLocalizations t) {
    if (v == null || v.isEmpty) return t.required_field;
    if (!_passwordRe.hasMatch(v)) return t.weak_password;
    return null;
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _currentErr = null;
    });

    try {
      if (_current.text.trim().isEmpty) {
        setState(() => _currentErr = t.required_field);
        return;
      }

      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _current.text.trim(),
      );

      try {
        await user.reauthenticateWithCredential(cred);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          setState(() => _currentErr = t.invalid_code);
          return;
        } else {
          setState(() => _error = e.message ?? e.code);
          return;
        }
      }

      if (_new1.text.trim() == _current.text.trim()) {
        setState(() => _error = t.error_occurred);
        return;
      }

      if (!_form.currentState!.validate()) return;

      if (_new1.text != _new2.text) {
        setState(() => _error = t.passwords_not_match);
        return;
      }

      await user.updatePassword(_new1.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.password_reset_success,
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: theme.colorScheme.primary,
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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

                  Text(
                    t.change_password,
                    style: theme.textTheme.headlineMedium!.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CURRENT PASSWORD
                  TextFormField(
                    controller: _current,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: t.password,
                      prefixIcon: Icon(Icons.lock_outline,
                          color: theme.colorScheme.primary),
                      errorText: _currentErr,
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // NEW PASSWORD
                  PasswordInput(
                    controller: _new1,
                    label: t.new_password,
                    validator: (v) => _validateNewPassword(v, t),
                  ),

                  const SizedBox(height: 12),

                  // CONFIRM PASSWORD
                  PasswordInput(
                    controller: _new2,
                    label: t.confirm_password,
                    validator: (v) =>
                    v != _new1.text ? t.passwords_not_match : null,
                  ),

                  const SizedBox(height: 16),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),

                  // SAVE BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                    )
                        : Text(
                      t.save,
                      style: TextStyle(color: theme.colorScheme.onPrimary),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      t.back,
                      style:
                      TextStyle(color: theme.colorScheme.primary),
                    ),
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
