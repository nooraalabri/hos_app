import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_input.dart';
import '../widgets/password_input.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notify_service.dart';
import '../models/app_user.dart';
import '../routes.dart';

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
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$'
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

      final cred = await AuthService.registerWithEmail(
        email: _email.text.trim(),
        password: _pass.text,
        profile: profile,
      );

      final uid = cred.user!.uid;
      await FS.createUser(uid, {'approved': false});

      // ✅ تنبيه الهوسبيتل أدمن
      try {
        final chosen = hospitals.firstWhere(
              (h) => h['id'] == hospitalId,
          orElse: () => <String, dynamic>{},
        );
        final hospitalEmail = chosen['email'] as String?;
        if (hospitalEmail != null && hospitalEmail.isNotEmpty) {
          await NotifyService.notifyHospAdmin(
            doctorName: _name.text.trim(),
            hospAdminEmail: hospitalEmail,
            hospitalId: hospitalId!,
          );
        }
      } catch (e) {
        debugPrint("NotifyService error notifyHospAdmin: $e");
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleRouter,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                Text('Register Doctor',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),

                AppInput(
                  controller: _email,
                  label: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),

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

                AppInput(
                  controller: _name,
                  label: 'Full name',
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                AppInput(
                  controller: _spec,
                  label: 'Specialization',
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 18),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),

                ElevatedButton(
                  onPressed: (_submitting || noHospitals) ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
