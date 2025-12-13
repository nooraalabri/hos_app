import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/otp_service.dart';

class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final TextEditingController _c = TextEditingController();

  String email = '';
  String? err;
  bool checking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      checking = true;
      err = null;
    });

    final ok = await OtpService.verify(email, _c.text.trim());

    if (!mounted) return;

    setState(() => checking = false);

    if (ok) {
      Navigator.pushNamed(context, AppRoutes.reset, arguments: email);
    } else {
      setState(() =>
      err = AppLocalizations.of(context)!.invalidOrExpired,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              Text(
                t.enterRecoveryCode,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // ✔ النسخة المصححة بدون deprecated
              TextField(
                controller: _c,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: t.hintCode,
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor ??
                      theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (err != null)
                Text(
                  err!,
                  style: const TextStyle(color: Colors.red),
                ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: checking ? null : _verify,
                child: checking
                    ? CircularProgressIndicator(
                  color: theme.colorScheme.onPrimary,
                )
                    : Text(
                  t.send,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
