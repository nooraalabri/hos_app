import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'qr_page.dart';
import 'ui.dart';
import 'patient_drawer.dart';
import '../services/notification_service.dart';

class ProfilePageBody extends StatefulWidget {
  static const route = '/patient/profile';
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

  Future<void> _testNotification(String uid) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Sending test notification...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Send test notification
      await NotificationService.sendFCMNotification(
        userId: uid,
        title: 'Test Notification',
        body: 'This is a test push notification! If you received this, notifications are working correctly. 🎉',
        data: {
          'type': 'test_notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test notification sent! Check your device for the push notification.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error sending test notification: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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

        return AppScaffold(
          title: 'My Profile',
          drawer: const PatientDrawer(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2D515C),
                        const Color(0xFF2D515C).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF2D515C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _name.text.isEmpty ? 'Patient' : _name.text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_edit)
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _edit = true),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2D515C),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          if (_edit) ...[
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _edit = false),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _saving ? null : () => _save(uid),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2D515C),
                                      ),
                                    )
                                  : const Icon(Icons.save, size: 18),
                              label: Text(_saving ? 'Saving...' : 'Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2D515C),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Personal Information Card
                _buildInfoCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  children: _edit
                      ? _buildEditPersonalInfo()
                      : _buildViewPersonalInfo(email),
                ),
                const SizedBox(height: 16),

                // Medical Information Card
                _buildInfoCard(
                  title: 'Medical Information',
                  icon: Icons.medical_information_outlined,
                  subtitle: 'Visible to doctors only',
                  children: _edit
                      ? []
                      : _buildViewMedicalInfo(),
                ),
                const SizedBox(height: 16),

                // QR Code Button
                if (!_edit)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        QRPage.route,
                        arguments: {
                          ...data,
                          'uid': uid,
                        },
                      ),
                      icon: const Icon(Icons.qr_code, size: 24),
                      label: const Text(
                        'Show QR Code',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D515C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Test Notification Button
                if (!_edit)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Test Push Notification',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Test if push notifications are working correctly',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _testNotification(uid),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Send Test Notification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D515C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2D515C), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D515C),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  List<Widget> _buildViewPersonalInfo(String email) {
    return [
      _buildInfoRow(Icons.person, 'Name', _name.text.isEmpty ? '—' : _name.text),
      _buildInfoRow(Icons.badge, 'Civil Number', _civil.text.isEmpty ? '—' : _civil.text),
      _buildInfoRow(Icons.calendar_today, 'Date of Birth', _dob.text.isEmpty ? '—' : _dob.text),
      _buildInfoRow(Icons.email, 'Email', email),
      _buildInfoRow(Icons.phone, 'Phone', _phone.text.isEmpty ? '—' : _phone.text),
      _buildInfoRow(Icons.monitor_weight, 'Weight', _weight.text.isEmpty ? '—' : '${_weight.text} kg'),
      _buildInfoRow(Icons.height, 'Height', _height.text.isEmpty ? '—' : '${_height.text} cm'),
      _buildInfoRow(Icons.bloodtype, 'Blood Type', _bloodType.isEmpty ? '—' : _bloodType),
    ];
  }

  List<Widget> _buildEditPersonalInfo() {
    return [
      _field('Name', _name),
      _field('Civil Number', _civil, keyboardType: TextInputType.number),
      GestureDetector(
        onTap: _pickDob,
        child: AbsorbPointer(child: _field('Date of Birth', _dob)),
      ),
      _field('Phone', _phone, keyboardType: TextInputType.phone),
      _field('Weight (kg)', _weight, keyboardType: TextInputType.number),
      _field('Height (cm)', _height, keyboardType: TextInputType.number),
      _buildBloodTypeDropdown(),
    ];
  }

  List<Widget> _buildViewMedicalInfo() {
    return [
      _buildInfoRow(Icons.medical_services, 'Chronic Diseases', _chronic.text.isEmpty ? 'None' : _chronic.text),
      _buildInfoRow(Icons.warning, 'Allergies', _allergy.text.isEmpty ? 'None' : _allergy.text),
      _buildInfoRow(Icons.medication, 'Medications', _meds.text.isEmpty ? 'None' : _meds.text),
      _buildInfoRow(Icons.health_and_safety, 'General Condition', _condition.text.isEmpty ? '—' : _condition.text),
    ];
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2D515C).withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D515C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: _bloodType.isEmpty ? null : _bloodType,
        items: bloodTypes
            .map((type) => DropdownMenuItem(
          value: type,
          child: Text(type, style: const TextStyle(color: Color(0xFF2D515C))),
        ))
            .toList(),
        onChanged: (val) => setState(() => _bloodType = val ?? ''),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2D515C)),
        decoration: InputDecoration(
          labelText: 'Blood Type',
          labelStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D515C), width: 2),
          ),
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Color(0xFF2D515C)),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFF2D515C)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D515C), width: 2),
          ),
        ),
      ),
    );
  }
}
