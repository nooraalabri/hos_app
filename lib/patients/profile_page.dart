import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/FaceScanRegisterScreen.dart';
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

  String? faceUrl;
  List<dynamic>? faceEmbedding;

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
      final civil = _civil.text.trim();
      if (civil.length != 8 || int.tryParse(civil) == null) {
        _snack(t.civilMustBe8Digits);
        return;
      }

      final phone = _phone.text.trim();
      final phoneReg = RegExp(r'^[79]\d{7}$');
      if (!phoneReg.hasMatch(phone)) {
        _snack(t.phoneMustStartWith7or9);
        return;
      }

      final weight = int.tryParse(_weight.text.trim());
      final height = int.tryParse(_height.text.trim());

      if (weight == null ||
          height == null ||
          weight <= 0 ||
          height <= 0 ||
          weight > 999 ||
          height > 999) {
        _snack(t.weightHeightInvalid);
        return;
      }

      final dobDate = DateTime.tryParse(_dob.text.trim());
      if (dobDate == null ||
          dobDate.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        _snack(t.dob7days);
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
        _snack(t.profileUpdated);
        _futureProfile =
            FirebaseFirestore.instance.collection('users').doc(uid).get();
      }
    } catch (e) {
      _snack('${t.error}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder(
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

        if (_bloodType.isEmpty) {
          _bloodType = data['bloodType'] ?? '';
        }

        faceUrl = data['faceUrl'];
        faceEmbedding = data['faceEmbedding'];

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
                      Text(_edit ? t.editProfile : t.myProfile,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: Icon(_edit ? Icons.close : Icons.edit,
                            color: cs.primary),
                        onPressed: ()=> setState(()=>_edit=!_edit),
                      )
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(t.personalInfo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  _infoBox(t, email, cs),

                  const SizedBox(height: 18),

                  Text(t.medicalInfoDoctorOnly,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  _medicalBox(t, cs),

                  const SizedBox(height: 22),

                  //=============== FACE RECOGNITION ===============
                  Text("Face Recognition",
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  if(faceUrl == null) ...[
                    PrimaryButton(
                      text:"Register Face",
                      onPressed:() async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_)=> FaceScanRegisterScreen(uid: uid)),
                        );

                        if(result!=null && result["success"]==true){
                          await FirebaseFirestore.instance.collection("users").doc(uid).set({
                            "faceUrl": result["faceUrl"],
                            "faceEmbedding": result["embedding"],
                          },SetOptions(merge:true));

                          setState(() {
                            faceUrl=result["faceUrl"];
                            faceEmbedding=result["embedding"];
                          });
                          _snack("Face Registered Successfully ✓");
                        }
                      },
                    )
                  ]
                  else ...[
                    Text("Face Registered ✓",
                        style: TextStyle(color: Colors.green,fontWeight: FontWeight.w600)),
                    const SizedBox(height:10),
                    Container(
                      height:140,
                      decoration:BoxDecoration(
                        borderRadius:BorderRadius.circular(12),
                        image:DecorationImage(image:NetworkImage(faceUrl!),fit:BoxFit.cover),
                        border:Border.all(color:Colors.green,width:2),
                      ),
                    ),
                    const SizedBox(height:8),
                    PrimaryButton(
                      filled:false,
                      text:"Re-Scan Face",
                      onPressed:() async {
                        final result=await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_)=> FaceScanRegisterScreen(uid: uid)),
                        );
                        if(result!=null && result["success"]==true){
                          await FirebaseFirestore.instance.collection("users").doc(uid).set({
                            "faceUrl": result["faceUrl"],
                            "faceEmbedding": result["embedding"],
                          },SetOptions(merge:true));

                          setState(() {
                            faceUrl=result["faceUrl"];
                            faceEmbedding=result["embedding"];
                          });
                          _snack("Face Updated Successfully ✓");
                        }
                      },
                    )
                  ],

                  const SizedBox(height:28),

                  if (_edit) _editSection(uid, t, cs),

                  if (!_edit)
                    Align(
                      alignment: Alignment.centerRight,
                      child: PrimaryButton(
                        filled: false,
                        text: t.showQr,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          QRPage.route,
                          arguments: {...data, 'uid': uid},
                        ),
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

  Widget _infoBox(AppLocalizations t, String email, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _row(t.name, _name.text, cs),
          _row(t.civilNumber, _civil.text, cs),
          _row(t.dob, _dob.text, cs),
          _row(t.email, email, cs),
          _row(t.phone, _phone.text, cs),
          _row(t.height, _height.text, cs),
          _row(t.weight, _weight.text, cs),
          _row(t.bloodType, _bloodType, cs),
        ],
      ),
    );
  }

  Widget _medicalBox(AppLocalizations t, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _row(t.chronicDiseases, _chronic.text, cs),
          _row(t.allergies, _allergy.text, cs),
          _row(t.medications, _meds.text, cs),
          _row(t.condition, _condition.text, cs),
        ],
      ),
    );
  }

  Widget _editSection(String uid, AppLocalizations t, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: cs.outline, height: 30),

        _field(t.name, _name, cs),
        _field(t.civilNumber, _civil, cs, keyboardType: TextInputType.number),

        GestureDetector(
          onTap: _pickDob,
          child: AbsorbPointer(child: _field(t.dob, _dob, cs)),
        ),

        _field(t.phone, _phone, cs, keyboardType: TextInputType.phone),
        _field(t.weight, _weight, cs, keyboardType: TextInputType.number),
        _field(t.height, _height, cs, keyboardType: TextInputType.number),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PrimaryButton(
              filled: false,
              text: t.cancel,
              onPressed: () => setState(() => _edit = false),
            ),
            PrimaryButton(
              text: _saving ? t.saving : t.save,
              onPressed: _saving ? null : () => _save(uid),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c, ColorScheme cs,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _row(String key, String val, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(key, style: TextStyle(color: cs.onSurface)),
          ),
          Expanded(
            child: Text(
              val.isEmpty ? '—' : val,
              style:
              TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
