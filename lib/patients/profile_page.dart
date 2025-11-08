import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  final List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  late Future<DocumentSnapshot<Map<String, dynamic>>> _futureProfile;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _futureProfile = FirebaseFirestore.instance.collection('users').doc(uid).get();
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
    final minAllowed = now.subtract(const Duration(days: 7)); // أقل من اليوم بـ7 أيام
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
    setState(() => _saving = true);
    try {
      // تحقق من الرقم المدني
      final civil = _civil.text.trim();
      if (civil.length != 8 || int.tryParse(civil) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Civil number must be exactly 8 digits')),
        );
        setState(() => _saving = false);
        return;
      }

      // تحقق من رقم الهاتف
      final phone = _phone.text.trim();
      final phoneReg = RegExp(r'^[79]\d{7}$'); // يبدأ ب7 أو 9 وعدده 8
      if (!phoneReg.hasMatch(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number must start with 7 or 9 and be 8 digits')),
        );
        setState(() => _saving = false);
        return;
      }

      // تحويل الوزن والطول إلى int
      final int? weight = int.tryParse(_weight.text.trim());
      final int? height = int.tryParse(_height.text.trim());

      // التحقق من أن الوزن والطول أرقام صحيحة وموجبة ولا تتعدى 3 digits
      if (weight == null ||
          height == null ||
          weight <= 0 ||
          height <= 0 ||
          weight > 999 ||
          height > 999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight and height must be positive numbers with max 3 digits')),
        );
        setState(() => _saving = false);
        return;
      }

      // التحقق من أن تاريخ الميلاد أقدم من 7 أيام
      final dobDate = DateTime.tryParse(_dob.text.trim());
      if (dobDate == null ||
          dobDate.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date of birth must be at least 7 days before today')),
        );
        setState(() => _saving = false);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
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
            .showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
        _futureProfile =
            FirebaseFirestore.instance.collection('users').doc(uid).get();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _futureProfile,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: Text('Profile not found'));
        }

        final data = snap.data!.data() ?? {};
        final email =
            data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';

        if (_name.text.isEmpty) _name.text = data['name'] ?? '';
        if (_civil.text.isEmpty) _civil.text = data['civilNumber'] ?? '';
        if (_dob.text.isEmpty) _dob.text = data['dob'] ?? '';
        if (_phone.text.isEmpty) _phone.text = data['phone'] ?? '';
        if (_weight.text.isEmpty) _weight.text = data['weight']?.toString() ?? '';
        if (_height.text.isEmpty) _height.text = data['height']?.toString() ?? '';
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
                        _edit ? 'Edit Profile' : 'My Profile',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: Icon(
                            _edit ? Icons.close : Icons.edit,
                            color: Colors.white),
                        onPressed: () => setState(() => _edit = !_edit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Personal Information',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _row('Name', _name.text),
                        _row('Civil Number', _civil.text),
                        _row('Date of Birth', _dob.text),
                        _row('Email', email),
                        _row('Phone', _phone.text),
                        _row('Weight (kg)', _weight.text),
                        _row('Height (cm)', _height.text),
                        _row('Blood Type', _bloodType),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Medical Information (Doctor only)',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _row('Chronic Diseases', _chronic.text),
                        _row('Allergies', _allergy.text),
                        _row('Medications', _meds.text),
                        _row('Condition', _condition.text),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  if (_edit) _editSection(uid),
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
                        child: const Text('Show QR Code'),
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

  Widget _editSection(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white30, height: 30),
        const Text('Edit Personal Information',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        _field('Name', _name),
        _field('Civil Number', _civil, keyboardType: TextInputType.number),
        GestureDetector(
          onTap: _pickDob,
          child: AbsorbPointer(child: _field('Date of Birth', _dob)),
        ),
        _field('Phone', _phone, keyboardType: TextInputType.phone),
        _field('Weight (kg)', _weight, keyboardType: TextInputType.number),
        _field('Height (cm)', _height, keyboardType: TextInputType.number),

        // Dropdown blood type
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<String>(
            value: _bloodType.isEmpty ? null : _bloodType,
            items: bloodTypes
                .map((type) => DropdownMenuItem(
              value: type,
              child:
              Text(type, style: const TextStyle(color: Colors.white)),
            ))
                .toList(),
            onChanged: (val) => setState(() => _bloodType = val ?? ''),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Blood Type',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text(_saving ? 'Saving...' : 'Save'),
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
              child:
              Text(key, style: const TextStyle(color: Colors.white70))),
          Expanded(
            child: Text(val.isEmpty ? '—' : val,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
