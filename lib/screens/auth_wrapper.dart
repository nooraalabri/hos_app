// lib/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_router.dart';
import 'welcome.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  User? _user;
  String? _savedRole;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Load saved role from local storage
      final prefs = await SharedPreferences.getInstance();
      _savedRole = prefs.getString('user_role');
      
      // Check Firebase auth state
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // User is logged in, verify role and save FCM token
        await _verifyAndSaveRole(user.uid);
        await _saveFcmToken(user.uid);
      } else {
        // User not logged in, clear saved role
        await prefs.remove('user_role');
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _user = FirebaseAuth.instance.currentUser;
        });
      }
    }

    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        if (user != null) {
          _verifyAndSaveRole(user.uid);
          _saveFcmToken(user.uid);
        } else {
          // User logged out, clear saved role
          SharedPreferences.getInstance().then((prefs) {
            prefs.remove('user_role');
          });
        }
      }
    });
  }

  Future<void> _verifyAndSaveRole(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        final role = userDoc.data()?['role']?.toString() ?? '';
        if (role.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', role);
          _savedRole = role;
          debugPrint('✅ Role saved to local storage: $role');
        }
      }
    } catch (e) {
      debugPrint('Error saving role: $e');
    }
  }

  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && mounted) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
        debugPrint('✅ FCM Token saved for user: $uid');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  Future<void> _loadSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedRole = prefs.getString('user_role');
      if (_savedRole != null) {
        debugPrint('✅ Loaded saved role from local storage: $_savedRole');
      }
    } catch (e) {
      debugPrint('❌ Error loading saved role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user is logged in, route them to their home screen
    if (_user != null) {
      return const RoleRouter();
    }

    // If user is not logged in, show welcome screen
    return const WelcomeScreen();
  }
}

