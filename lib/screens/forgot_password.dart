import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_input.dart';
import '../services/otp_service.dart';
import '../routes.dart';
import '../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool sending = false;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim();

    setState(() {
      sending = true;
      _err = null;
    });

    try {
      await OtpService
          .sendOtp(email: email)
          .timeout(const Duration(seconds: 8), onTimeout: () {
        // لا نرمي خطأ عند انتهاء المهلة – نكمل UX
      });

      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.enterCode, arguments: email);
    } catch (e) {
      _err = 'Failed to send code. Try again.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_err!)),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)?.forgot_password ?? 'Forgot\npassword',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                AppInput(
                  controller: _email,
                  label: AppLocalizations.of(context)?.email ?? 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                ),

                const Spacer(),

                if (_err != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_err!, style: const TextStyle(color: Colors.red)),
                  ),

                Center(
                  child: ElevatedButton(
                    onPressed: sending ? null : _send,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 12),
                      child: sending
                          ? const CircularProgressIndicator()
                          : Text(AppLocalizations.of(context)?.send_code ?? 'Send'),
                    ),
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
