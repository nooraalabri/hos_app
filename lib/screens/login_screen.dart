import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../l10n/app_localizations.dart';

import '../routes.dart';
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
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 🔹 تسجيل الدخول
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        throw Exception("UID is null");
      }

      // 🔹 جلب الدور
      final role = await _getUserRole(uid);
      if (role == null) {
        setState(() => _error = t.loginFailed);
        return;
      }

      // 🔹 حفظ FCM Token
      await _saveFcmToken(uid);

      if (!mounted) return;

      // 🔹 التوجيه حسب الدور
      switch (role) {
        case 'headadmin':
          _go(AppRoutes.headAdminHome);
          break;
        case 'hospitaladmin':
          _go(AppRoutes.hospitalAdminHome);
          break;
        case 'doctor':
          _go(AppRoutes.doctorHome);
          break;
        case 'patient':
          _go(AppRoutes.patientHome);
          break;
        default:
          setState(() => _error = t.unknownRole);
      }
    } on FirebaseAuthException catch (e) {
      String msg = t.loginFailed;

      if (e.code == 'user-not-found') msg = t.noAccountForEmail;
      if (e.code == 'wrong-password') msg = t.incorrectPassword;
      if (e.code == 'invalid-credential') msg = t.invalidCredential;

      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("⚠️ Error saving FCM token: $e");
    }
  }

  Future<String?> _getUserRole(String uid) async {
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  void _go(String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  Image.asset('assets/logo.png', height: 120),
                  const SizedBox(height: 10),

                  Text(t.welcomeBack,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 20),

                  // Email
                  AppInput(
                    controller: _email,
                    label: t.email,
                    hint: t.enterYourEmail,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                    (v == null || !v.contains('@')) ? t.enterValidEmail : null,
                  ),
                  const SizedBox(height: 12),

                  // Password
                  PasswordInput(
                    controller: _pass,
                    label: t.password,
                    validator: (v) =>
                    v != null && v.length >= 8 ? null : t.min8chars,
                  ),
                  const SizedBox(height: 8),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.forgot),
                      child: Text(t.forgotPasswordQ),
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),

                  // Login button
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(t.login),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.newUser),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.selectRole),
                        child: Text(t.signUp),
                      ),
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
