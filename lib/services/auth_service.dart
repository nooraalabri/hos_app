import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../routes.dart';
import '../models/app_user.dart';
import 'firestore_service.dart';

enum SetPassResult { ok, needLogin, error }

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) {
    return login(email, password);
  }
  static Future<void> logoutAndGoWelcome(BuildContext context) async {
    await logout(); // signOut من Firebase
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.welcome, // أو AppRoutes.login إذا تبين
          (_) => false,
    );
  }

  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required AppUser profile,
  }) async {
    // 1) أنشئ المستخدم في Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // 2) عدّل displayName (اختياري)
    await cred.user?.updateDisplayName(profile.name);

    // 3) حضّر بيانات Firestore
    final uid = cred.user!.uid;
    final data = _userMapFromProfile(uid, email, profile);

    // 4) اكتب المستند
    await FS.createUser(uid, data);

    return cred;
  }

  /// جلب بروفايل المستخدم من Firestore كـ AppUser
  static Future<AppUser> fetchProfile(String uid) async {
    final snap = await FS.users.doc(uid).get();
    final m = snap.data() ?? <String, dynamic>{};

    return AppUser(
      uid: uid,
      email: m['email'] ?? _auth.currentUser?.email ?? '',
      role: m['role'] ?? 'patient',
      name: m['name'],
      hospitalId: m['hospitalId'],
      specialization: m['specialization'],
      approved: (m['approved'] ?? true) == true,
    );
  }

  /// تسجيل خروج
  static Future<void> logout() => _auth.signOut();

  /// تغيير كلمة السر (يعمل فقط إن كان فيه مستخدم مسجّل والـ login حديث)
  static Future<SetPassResult> setNewPassword(String email, String newPass) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return SetPassResult.needLogin;

      await user.updatePassword(newPass);
      return SetPassResult.ok;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') return SetPassResult.needLogin;
      return SetPassResult.error;
    } catch (_) {
      return SetPassResult.error;
    }
  }

  // ===== Helpers =====
  static Map<String, dynamic> _userMapFromProfile(
      String uid,
      String email,
      AppUser p,
      ) {
    final isAutoApproved = p.role == 'patient';

    return <String, dynamic>{
      'uid': uid,
      'email': email.trim(),
      'role': p.role,
      'name': p.name,
      'hospitalId': p.hospitalId,
      'specialization': p.specialization,
      'approved': p.approved ?? isAutoApproved,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
