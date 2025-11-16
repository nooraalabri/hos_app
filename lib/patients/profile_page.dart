import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'patient_drawer.dart';
import 'qr_page.dart';
import 'ui.dart';

class ProfilePageBody extends StatefulWidget {
  const ProfilePageBody({super.key});

  @override
  State<ProfilePageBody> createState() => _ProfilePageBodyState();
}

class _ProfilePageBodyState extends State<ProfilePageBody> {
  bool _edit = false;
  bool _saving = false;

  final _name = TextEditingController();
  final _civil = TextEditingController();
  final _dob = TextEditingController();
  final _phone = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  String _bloodType = '';

  final _chronic = TextEditingController();
  final _condition = TextEditingController();
  final _allergy = TextEditingController();
  final _meds = TextEditingController();

  final List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  late Future<DocumentSnapshot<Map<String, dynamic>>> _futureProfile;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _futureProfile =
        FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  @override
  void dispose() {
    _name.dispose();
    _civil.dispose();
    _dob.dispose();
    _phone.dispose();
    _weight.dispose();
    _height.dispose();
    _chronic.dispose();
    _condition.dispose();
    _allergy.dispose();
    _meds.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final minAllowed = now.subtract(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: minAllowed,
    );
    if (picked != null) {
      _dob.text =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _save(String uid) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      // Civil number
      final civil = _civil.text.trim();
      if (civil.length != 8 || int.tryParse(civil) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.civilMustBe8Digits)),
        );
        setState(() => _saving = false);
        return;
      }

      // Phone
      final phone = _phone.text.trim();
      final phoneReg = RegExp(r'^[79]\d{7}$');
      if (!phoneReg.hasMatch(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.phoneMustStartWith7or9)),
        );
        setState(() => _saving = false);
        return;
      }

      // Weight & Height
      final int? weight = int.tryParse(_weight.text.trim());
      final int? height = int.tryParse(_height.text.trim());
      if (weight == null ||
          height == null ||
          weight <= 0 ||
          height <= 0 ||
          weight > 999 ||
          height > 999) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.weightHeightInvalid)),
        );
        setState(() => _saving = false);
        return;
      }

      // DOB
      final dobDate = DateTime.tryParse(_dob.text.trim());
      if (dobDate == null ||
          dobDate.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.dob7days)),
        );
        setState(() => _saving = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'name': _name.text.trim(),
        'civilNumber': civil,
        'dob': _dob.text.trim(),
        'phone': phone,
        'weight': weight,
        'height': height,
        'bloodType': _bloodType.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _edit = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.profileUpdated)));
        _futureProfile =
            FirebaseFirestore.instance.collection('users').doc(uid).get();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.error}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _futureProfile,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Center(child: Text(t.profileNotFound));
        }

        final data = snap.data!.data() ?? {};
        final email =
            data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';

        if (_name.text.isEmpty) _name.text = data['name'] ?? '';
        if (_civil.text.isEmpty) _civil.text = data['civilNumber'] ?? '';
        if (_dob.text.isEmpty) _dob.text = data['dob'] ?? '';
        if (_phone.text.isEmpty) _phone.text = data['phone'] ?? '';
        if (_weight.text.isEmpty) {
          _weight.text = data['weight']?.toString() ?? '';
        }
        if (_height.text.isEmpty) {
          _height.text = data['height']?.toString() ?? '';
        }
        if (_bloodType.isEmpty) _bloodType = data['bloodType'] ?? '';

        _chronic.text =
            ((data['chronic'] as List?)?.cast<String>() ?? []).join(', ');
        _condition.text = data['generalCondition'] ?? '';
        _allergy.text = data['allergies'] ?? '';
        _meds.text = data['medications'] ?? '';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PrimaryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _edit ? t.editProfile : t.myProfile,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: Icon(
                          _edit ? Icons.close : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => _edit = !_edit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    t.personalInfo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),

                  _infoBox(t, email),

                  const SizedBox(height: 16),

                  Text(
                    t.medicalInfoDoctorOnly,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),

                  _medicalBox(t),

                  const SizedBox(height: 20),

                  if (_edit) _editSection(uid, t),

                  if (!_edit)
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          QRPage.route,
                          arguments: {
                            ...data,
                            'uid': uid,
                          },
                        ),
                        child: Text(t.showQr),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoBox(AppLocalizations t, String email) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _row(t.name, _name.text),
          _row(t.civilNumber, _civil.text),
          _row(t.dob, _dob.text),
          _row(t.email, email),
          _row(t.phone, _phone.text),
          _row(t.weight, _weight.text),
          _row(t.height, _height.text),
          _row(t.bloodType, _bloodType),
        ],
      ),
    );
  }

  Widget _medicalBox(AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _row(t.chronicDiseases, _chronic.text),
          _row(t.allergies, _allergy.text),
          _row(t.medications, _meds.text),
          _row(t.condition, _condition.text),
        ],
      ),
    );
  }

  Widget _editSection(String uid, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white30, height: 30),
        Text(
          t.editPersonalInfo,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),

        _field(t.name, _name),
        _field(t.civilNumber, _civil, keyboardType: TextInputType.number),

        GestureDetector(
          onTap: _pickDob,
          child: AbsorbPointer(child: _field(t.dob, _dob)),
        ),

        _field(t.phone, _phone, keyboardType: TextInputType.phone),
        _field(t.weight, _weight, keyboardType: TextInputType.number),
        _field(t.height, _height, keyboardType: TextInputType.number),

        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<String>(
            value: _bloodType.isEmpty ? null : _bloodType,
            items: bloodTypes
                .map(
                  (type) => DropdownMenuItem(
                value: type,
                child: Text(type,
                    style: const TextStyle(color: Colors.white)),
              ),
            )
                .toList(),
            onChanged: (val) => setState(() => _bloodType = val ?? ''),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            decoration: InputDecoration(
              labelText: t.bloodType,
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white70)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: AppColors.primary, width: 2)),
            ),
            dropdownColor: const Color(0xFF2D515C),
            style: const TextStyle(color: Colors.white),
          ),
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _edit = false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
                foregroundColor: Colors.white,
              ),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
              ),
              child: Text(_saving ? t.saving : t.save),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white70)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    );
  }

  Widget _row(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(key, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              val.isEmpty ? '—' : val,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
