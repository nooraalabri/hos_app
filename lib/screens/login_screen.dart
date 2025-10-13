import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../widgets/app_input.dart';
import '../widgets/password_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      print("🔑 Trying login with Email: '${_email.text.trim()}', Password: '${_pass.text}'");

      await AuthService.login(_email.text.trim(), _pass.text.trim());

      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.roleRouter);
    } catch (e) {
      String msg = e.toString();
      if (msg.contains("invalid-credential")) {
        msg = "Invalid email or password.";
      } else if (msg.contains("user-not-found")) {
        msg = "No account found for this email.";
      } else if (msg.contains("wrong-password")) {
        msg = "Incorrect password.";
      }
      setState(() => _error = msg);
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
                  Image.asset(
                    'assets/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 10),
                  Text('welcome back', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  AppInput(
                    controller: _email,
                    label: 'E-mail',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v==null || !v.contains('@')) ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  PasswordInput(
                    controller: _pass,
                    label: 'Password',
                    validator: (v) => v!=null && v.length>=8 ? null : 'Min 8 chars',
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.forgot),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  if (_error!=null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 6),
                  ElevatedButton(
                    onPressed: _loading?null:_submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      child: _loading ? const CircularProgressIndicator() : const Text('login'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('new user? '),
                      TextButton(
                        onPressed: ()=>Navigator.pushReplacementNamed(context, AppRoutes.selectRole),
                        child: const Text('Sign up'),
                      )
                    ],
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
