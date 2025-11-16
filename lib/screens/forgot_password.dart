import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_input.dart';
import '../services/otp_service.dart';
import '../services/email_api.dart';
import '../routes.dart';

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
    final t = AppLocalizations.of(context)!;

    setState(() {
      sending = true;
      _err = null;
    });

    try {
      await OtpService
          .sendOtp(email: email, emailApiBaseUrl: EmailApiConfig.baseUrl)
          .timeout(const Duration(seconds: 8), onTimeout: () {
        // UX: لا نرمي خطأ حتى لو انتهت المهلة
      });

      if (!mounted) return;

      Navigator.pushNamed(context, AppRoutes.enterCode, arguments: email);
    } catch (e) {
      _err = t.failedToSend;
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
    final t = AppLocalizations.of(context)!;

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

                // العنوان
                Text(
                  t.forgotPasswordTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 24),

                // حقل الإيميل
                AppInput(
                  controller: _email,
                  label: t.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? t.enterValidEmail : null,
                ),

                const Spacer(),

                if (_err != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _err!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                Center(
                  child: ElevatedButton(
                    onPressed: sending ? null : _send,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 12),
                      child: sending
                          ? const CircularProgressIndicator()
                          : Text(t.send),
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
