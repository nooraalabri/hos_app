import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

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

  // ======================================================
  // 🔵 FACE LOGIN (Real-time Face Scan)
  // ======================================================
  Future<void> _loginWithFace() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // نفتح صفحة Face Scan
      final result = await Navigator.pushNamed(
        context,
        "/face-scan-login",
      );

      if (result == null || result is! Map) {
        setState(() => _loading = false);
        return;
      }

      final success = result["success"] == true;
      final uid = result["uid"];
      final msg = result["message"];

      if (!success) {
        setState(() => _error = msg ?? "Face not recognized.");
        return;
      }

      // قراءة بيانات المستخدم
      final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (!doc.exists) {
        setState(() => _error = "User not found.");
        return;
      }

      final role = doc["role"];

      // توجيه حسب role
      switch (role) {
        case "patient":
          _go(AppRoutes.patientHome);
          break;
        case "doctor":
          _go(AppRoutes.doctorHome);
          break;
        case "hospitaladmin":
          _go(AppRoutes.hospitalAdminHome);
          break;
        case "headadmin":
          _go(AppRoutes.headAdminHome);
          break;
        default:
          setState(() => _error = "Unknown role");
      }

    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ======================================================
  // 🔵 NORMAL LOGIN
  // ======================================================
  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

    if (!_form.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      final uid = cred.user?.uid;
      if (uid == null) throw Exception("UID is null");

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        await cred.user!.delete();
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your account has been removed by the administrator."),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
        return;
      }

      final role = doc.data()?['role'] as String?;

      // حفظ FCM Token
      await _saveFcmToken(uid);

      if (!mounted) return;

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
    } catch (_) {}
  }

  void _go(String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  // ======================================================
  // 🔵 UI
  // ======================================================
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
                  Image.asset(
                    'assets/logo.png',
                    height: 120,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    t.welcomeBack,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  AppInput(
                    controller: _email,
                    label: t.email,
                    hint: t.enterYourEmail,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                    (v == null || !v.contains('@')) ? t.enterValidEmail : null,
                  ),
                  const SizedBox(height: 12),

                  PasswordInput(
                    controller: _pass,
                    label: t.password,
                    validator: (v) => v != null && v.length >= 8 ? null : t.min8chars,
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.forgot),
                      child: Text(
                        t.forgotPasswordQ,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(t.login),
                  ),

                  const SizedBox(height: 15),

                  // ------------------------------
                  // 🔵 FACE LOGIN BUTTON
                  // ------------------------------
                  TextButton(
                    onPressed: _loading ? null : _loginWithFace,
                    child: Text(
                      "Login with Face Recognition",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.newUser,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, AppRoutes.selectRole),
                        child: Text(
                          t.signUp,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
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
