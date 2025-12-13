import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_input.dart';
import '../widgets/password_input.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';
import '../routes.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _civil = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _civil.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  // DOB Picker
  Future<void> _pickDob() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );

    if (picked != null) {
      _dob.text = "${picked.year}-${picked.month}-${picked.day}";
      setState(() {});
    }
  }

  // Submit Registration
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final cred = await AuthService.registerWithEmail(
        email: _email.text.trim(),
        password: _pass.text,
        profile: AppUser(
          uid: '',
          email: _email.text.trim(),
          role: 'patient',
          name: _name.text.trim(),
        ),
      );

      final uid = cred.user!.uid;

      // Create user without face first
      await FS.createUser(uid, {
        'name': _name.text.trim(),
        'dob': _dob.text.trim(),
        'civilNumber': _civil.text.trim(),
        'email': _email.text.trim(),
        'role': 'patient',
        'faceRegistered': false,      // مهم لنعرف حالته بعدين
        'createdAt': DateTime.now(),
      });

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.patientHome,
            (_) => false,
      );

    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(size: 90),
                const SizedBox(height: 20),

                Text(t.register,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26,fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                AppInput(controller:_name,label:t.myName,
                    validator:(v)=>v!.isEmpty?t.required:null),
                const SizedBox(height:12),

                GestureDetector(
                  onTap:_pickDob,
                  child:AbsorbPointer(
                    child: AppInput(
                        controller:_dob,
                        label:t.dateOfBirth,
                        validator:(v)=>v!.isEmpty?t.required:null),
                  ),
                ),
                const SizedBox(height:12),

                AppInput(controller:_civil,label:t.civilNumber,
                    keyboardType:TextInputType.number,
                    validator:(v)=>v!.length!=8?"Must be 8 digits":null),
                const SizedBox(height:12),

                AppInput(controller:_email,label:t.email,
                    validator:(v)=>!v!.contains("@")?"Invalid Email":null),
                const SizedBox(height:12),

                PasswordInput(controller:_pass,label:t.password),
                const SizedBox(height:12),

                PasswordInput(controller:_pass2,label:t.confirmPassword,
                    validator:(v)=>v!=_pass.text?"Passwords don't match":null),
                const SizedBox(height:20),

                if(_error!=null)
                  Text(_error!,textAlign:TextAlign.center,style:const TextStyle(color:Colors.red)),

                ElevatedButton(
                  onPressed:_loading?null:_submit,
                  child:_loading
                      ? const CircularProgressIndicator(color:Colors.white)
                      : Text(t.signUp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
