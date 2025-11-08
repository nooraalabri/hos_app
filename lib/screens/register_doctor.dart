import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_input.dart';
import '../widgets/password_input.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';
import '../routes.dart';
import '../services/email_api.dart'; // 🟢 استدعاء ملف الإيميل
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key});

  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _spec = TextEditingController();

  String? hospitalId;
  List<Map<String, dynamic>> hospitals = [];

  bool _fetchingHospitals = true;
  bool _submitting = false;
  String? _error;

  final RegExp _passRe = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      final list = await FS.listHospitals(onlyApproved: true);
      if (!mounted) return;
      setState(() {
        hospitals = list;
        _fetchingHospitals = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load hospitals: $e';
        _fetchingHospitals = false;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    _spec.dispose();
    super.dispose();
  }

  // ✅ إرسال إشعار للهوسبتل أدمن
  Future<void> _notifyHospAdmin({
    required String doctorName,
    required String hospAdminEmail,
    required String hospitalId,
  }) async {
    final apiUrl = '${EmailApiConfig.baseUrl}/notify-hospadmin'; // 🔗 يأخذ العنوان الصحيح تلقائيًا

    try {
      final res = await http
          .post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorName': doctorName,
          'hospAdminEmail': hospAdminEmail,
          'hospitalId': hospitalId,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        debugPrint('✅ Email sent successfully to hospital admin.');
      } else {
        debugPrint('❌ Failed to send email: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || hospitalId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final profile = AppUser(
        uid: 'temp',
        email: _email.text.trim(),
        role: 'doctor',
        name: _name.text.trim(),
        hospitalId: hospitalId,
        specialization: _spec.text.trim(),
      );

      // 🔐 تسجيل الدكتور في Firebase
      final cred = await AuthService.registerWithEmail(
        email: _email.text.trim(),
        password: _pass.text,
        profile: profile,
      );

      final uid = cred.user!.uid;

      // 🧾 إنشاء مستند المستخدم في Firestore
      await FS.createUser(uid, {
        'role': 'doctor',
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'hospitalId': hospitalId,
        'specialization': _spec.text.trim(),
        'approved': false,
      });

      // 📬 إرسال إشعار للإيميل الخاص بالهوسبتل
      try {
        final selectedHospital = hospitals.firstWhere(
              (h) => h['id'] == hospitalId,
          orElse: () => {},
        );

        final hospEmail = selectedHospital['email']?.toString();
        if (hospEmail != null && hospEmail.isNotEmpty) {
          debugPrint('📨 Sending email to: $hospEmail');
          await _notifyHospAdmin(
            doctorName: _name.text.trim(),
            hospAdminEmail: hospEmail,
            hospitalId: hospitalId!,
          );
        } else {
          debugPrint('⚠️ No valid hospital email found.');
        }
      } catch (e) {
        debugPrint('❌ notifyHospAdmin() failed: $e');
      }

      if (!mounted) return;

      // ⏳ تحويل المستخدم لصفحة الانتظار
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.pendingApproval,
            (_) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetchingHospitals) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final noHospitals = hospitals.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(size: 90),
                Text(
                  'Register Doctor',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ====== EMAIL ======
                AppInput(
                  controller: _email,
                  label: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),

                // ====== HOSPITAL DROPDOWN ======
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Hospital'),
                  value: hospitalId,
                  items: hospitals.map<DropdownMenuItem<String>>((h) {
                    return DropdownMenuItem<String>(
                      value: h['id'].toString(),
                      child: Text(h['name']?.toString() ?? 'Unnamed hospital'),
                    );
                  }).toList(),
                  onChanged: noHospitals ? null : (v) => setState(() => hospitalId = v),
                  validator: (v) => noHospitals
                      ? 'No approved hospitals available'
                      : (v != null ? null : 'Select hospital'),
                ),
                const SizedBox(height: 12),

                // ====== PASSWORD ======
                PasswordInput(
                  controller: _pass,
                  label: 'Password',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (!_passRe.hasMatch(v)) {
                      return 'Min 8 incl. upper, lower, number & special';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ====== CONFIRM PASSWORD ======
                PasswordInput(
                  controller: _pass2,
                  label: 'Confirm password',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _pass.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ====== FULL NAME ======
                AppInput(
                  controller: _name,
                  label: 'Full name',
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // ====== SPECIALIZATION ======
                AppInput(
                  controller: _spec,
                  label: 'Specialization',
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 18),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),

                // ====== BUTTON ======
                ElevatedButton(
                  onPressed: (_submitting || noHospitals) ? null : _submit,
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: _submitting
                        ? const CircularProgressIndicator()
                        : const Text('Sign up'),
                  ),
                ),

                if (noHospitals) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'No approved hospitals found. Please try again later.',
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      InkWell(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                              (_) => false,
                        ),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
