import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hos_app/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_input.dart';
import '../widgets/password_input.dart';
import '../l10n/app_localizations.dart';

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

      // 🔹 جلب الدور من Firestore
      final role = await _getUserRole(uid);
      if (role == null) {
        setState(() => _error = "User profile not found in Firestore.");
        return;
      }

      // 🔹 حفظ الدور في Local Storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      await prefs.setString('user_uid', uid);

      // 🔹 حفظ FCM Token في Firestore
      await _saveFcmToken(uid);

      if (!mounted) return;

      // 🔹 التوجيه حسب الدور - استخدام مسارات مباشرة بدلاً من AppRoutes
      switch (role) {
        case 'headadmin':
          Navigator.of(context).pushNamedAndRemoveUntil('/headadmin/home', (route) => false);
          break;
        case 'hospitaladmin':
          Navigator.of(context).pushNamedAndRemoveUntil('/hospitaladmin/home', (route) => false);
          break;
        case 'doctor':
          Navigator.of(context).pushNamedAndRemoveUntil('/doctor/home', (route) => false);
          break;
        case 'patient':
          Navigator.of(context).pushNamedAndRemoveUntil('/patient/home', (route) => false);
          break;
        default:
          setState(() => _error = "Unknown role: $role");
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Login failed.";
      if (e.code == 'user-not-found') msg = "No account found for this email.";
      if (e.code == 'wrong-password') msg = "Incorrect password.";
      if (e.code == 'invalid-credential') msg = "Invalid email or password.";
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

  // ✅ جلب الدور من Firestore
  Future<String?> _getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  // ✅ التنقل إلى الصفحة المناسبة
  void _go(String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
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
                  Image.asset('assets/logo.png', height: 120),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)?.welcome_back ?? 'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),

                  // Email
                  AppInput(
                    controller: _email,
                    label: AppLocalizations.of(context)?.email ?? 'E-mail',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),

                  // Password
                  PasswordInput(
                    controller: _pass,
                    label: AppLocalizations.of(context)?.password ?? 'Password',
                    validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 chars',
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.forgot),
                      child: Text(AppLocalizations.of(context)?.forgot_password ?? 'Forgot Password?'),
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),

                  // Login button
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(AppLocalizations.of(context)?.login ?? 'Login'),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${AppLocalizations.of(context)?.register ?? 'New user'}? '),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, AppRoutes.selectRole),
                        child: Text(AppLocalizations.of(context)?.signup ?? 'Sign up'),
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
