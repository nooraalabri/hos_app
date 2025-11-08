import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditDoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> currentData;

  const EditDoctorProfileScreen({
    super.key,
    required this.doctorId,
    required this.currentData,
  });

  @override
  State<EditDoctorProfileScreen> createState() => _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<EditDoctorProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _specialization;
  late TextEditingController _address;
  late TextEditingController _image;

  bool _saving = false;
  String? _error;

  final Color primaryColor = const Color(0xFF00695C); // Teal 800
  final Color lightColor = const Color(0xFFE0F2F1);   // Teal 50
  final Color accentColor = const Color(0xFF009688);  // Teal 500

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.currentData['name'] ?? '');
    _email = TextEditingController(text: widget.currentData['email'] ?? '');
    _specialization = TextEditingController(text: widget.currentData['specialization'] ?? '');
    _address = TextEditingController(text: widget.currentData['address'] ?? '');
    _image = TextEditingController(text: widget.currentData['image'] ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _specialization.dispose();
    _address.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Please fill all required fields.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.doctorId).update({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'specialization': _specialization.text.trim(),
        'address': _address.text.trim(),
        'image': _image.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Error saving profile: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: accentColor),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: _fieldDecoration('Full Name', Icons.person),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _email,
                  decoration: _fieldDecoration('Email', Icons.email),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _specialization,
                  decoration: _fieldDecoration('Specialization', Icons.medical_information),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _address,
                  decoration: _fieldDecoration('Address', Icons.location_on),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _image,
                  decoration: _fieldDecoration('Profile Image URL (optional)', Icons.image),
                ),
                const SizedBox(height: 20),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
