import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = t.fillRequired);
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
            content: Text(t.saveSuccess),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = "${t.saveError} $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      labelStyle: TextStyle(color: theme.hintColor),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.editProfile,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: _inputDecoration(t.fullName, Icons.person),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _email,
                  decoration: _inputDecoration(t.email, Icons.email),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _specialization,
                  decoration: _inputDecoration(t.specialization, Icons.medical_information),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _address,
                  decoration: _inputDecoration(t.address, Icons.location_on),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _image,
                  decoration: _inputDecoration(t.profileImageUrl, Icons.image),
                ),
                const SizedBox(height: 20),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? CircularProgressIndicator(color: theme.colorScheme.onPrimary)
                        : Text(
                      t.saveChanges,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onPrimary,
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
