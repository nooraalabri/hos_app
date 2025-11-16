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
  final _c = TextEditingController();
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
    setState(() => checking = true);

    final ok = await OtpService.verify(email, _c.text.trim());

    setState(() => checking = false);

    if (ok) {
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.reset, arguments: email);
      }
    } else {
      setState(() =>
      err = AppLocalizations.of(context)!.invalidOrExpired);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // عنوان الصفحة
              Text(
                t.enterRecoveryCode,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _c,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: t.hintCode,
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
                onPressed: checking ? null : _verify,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 12),
                  child: checking
                      ? const CircularProgressIndicator()
                      : Text(t.send),
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
