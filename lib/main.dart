

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme.dart';
// DO NOT import routes.dart - we handle routes manually to avoid '/' conflict
import 'providers/app_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/notify_service.dart';
import 'screens/auth_wrapper.dart';

// Import all screens needed for routing
import 'screens/doctor_home.dart';
import 'pages/head_admin_home.dart';
import 'pages/hospital_admin_home.dart';
import 'screens/approve_doctors.dart';
import 'screens/approve_hospitals.dart';
import 'screens/pending_approval.dart';
import 'screens/welcome.dart';
import 'screens/login_screen.dart';
import 'screens/role_selection.dart';
import 'screens/register_patient.dart';
import 'screens/register_doctor.dart';
import 'screens/register_hospital.dart';
import 'screens/forgot_password.dart';
import 'screens/enter_code.dart';
import 'screens/reset_password.dart';
import 'screens/role_router.dart';
import 'screens/hospital_profile.dart';
import 'screens/hospital_reports.dart';
import 'screens/my_staff.dart';
import 'screens/head_admin_reports.dart';
import 'screens/change_password.dart';
import 'screens/settings_screen.dart';
import 'screens/social_media_post_screen.dart';
import 'screens/doctor/add_report_screen.dart';
import 'screens/doctor/edit_profile.dart';
import 'screens/doctor/reviews.dart';
import 'screens/doctor/weekly_shifts_screen.dart';
import 'screens/doctor/medical_records.dart';
import 'screens/doctor/my_shifts_screen.dart' as doctor;
import 'admin/manage_shifts_screen.dart' as admin;
import 'admin/hospital_doctor_reports_screen.dart';
import 'admin/hospital_patient_reports_screen.dart';
import 'patients/patient_home.dart';
import 'patients/profile_page.dart';
import 'patients/search_page.dart';
import 'patients/appointment_page.dart';
import 'patients/medical_reports_page.dart';
import 'patients/medicines_page.dart';
import 'patients/qr_page.dart';
import 'patients/patient_invoices_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background Message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotifyService.init(); // ✅ إعداد خدمة الإشعارات المحلية

  final token = await messaging.getToken();
  print('✅ FCM Token: $token');

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

// Helper function to get route builder - handles routes directly without using a map
// This avoids any potential evaluation of a routes table that might contain '/'
WidgetBuilder? _getRouteBuilder(String? routeName) {
  if (routeName == null || routeName == '/' || routeName == '/') {
    return null; // Handled separately in onGenerateRoute
  }
  
  // Handle routes using string literals - NO AppRoutes constants to avoid any map evaluation
  // This ensures Flutter never sees a routes table with '/' in it
  switch (routeName) {
    // Admin & Hospital routes
    case '/hospital-profile':
      return (_) => const HospitalProfileScreen();
    case '/hospital-reports':
      return (_) => const HospitalReportsScreen();
    case '/hospital/doctor-reports':
      return (_) => const HospitalDoctorReportsScreen();
    case '/hospital/patient-reports':
      return (_) => const HospitalPatientReportsScreen();
    case '/my-staff':
      return (_) => const MyStaffScreen();
    case '/head-admin-reports':
      return (_) => const HeadAdminReportsScreen();
    case '/approve-hospitals':
      return (_) => const ApproveHospitalsScreen();
    case '/approve-doctors':
      return (_) => const ApproveDoctorsScreen();
    case '/pending-approval':
      return (_) => const PendingApprovalScreen();
    case '/hospital/manage-shifts':
      return (_) => admin.ManageShiftsScreen();
    
    // Auth & Registration routes
    case '/login':
      return (_) => const LoginScreen();
    case '/select-role':
      return (_) => const RoleSelectionScreen();
    case '/register-patient':
      return (_) => const RegisterPatientScreen();
    case '/register-doctor':
      return (_) => const RegisterDoctorScreen();
    case '/register-hospital':
      return (_) => const RegisterHospitalScreen();
    case '/forgot':
      return (_) => const ForgotPasswordScreen();
    case '/enter-code':
      return (_) => const EnterCodeScreen();
    case '/reset':
      return (_) => const ResetPasswordScreen();
    case '/role-router':
      return (_) => const RoleRouter();
    
    // Home Pages
    case '/headadmin/home':
      return (_) => const HeadAdminHome();
    case '/hospitaladmin/home':
      return (_) => const HospitalAdminHome();
    case '/doctor/home':
      return (_) => DoctorHome(doctorId: FirebaseAuth.instance.currentUser!.uid);
    case '/patient/home':
      return (_) => const PatientHome();
    
    // Doctor Pages
    case '/doctor/add-report':
      return (_) => const Placeholder();
    case '/doctor/reviews':
      return (_) => ReviewsScreen(doctorId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown');
    case '/doctor/weekly-shifts':
      return (_) => ShiftsOverviewScreen(doctorId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown');
    case '/doctor/my-shifts':
      return (_) => doctor.MyShiftsScreen(doctorId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown');
    case '/doctor/edit-profile':
      return (_) => EditDoctorProfileScreen(doctorId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown', currentData: const {});
    case '/doctor/medical-records':
      return (_) => MedicalRecord(patientId: '', appointmentId: '', doctorId: '');
    
    // Patient Pages
    case '/patient/profile':
      return (_) => const ProfilePageBody();
    case '/patient/search':
      return (_) => const SearchPage();
    case '/patient/appointments':
      return (_) => const AppointmentPage();
    case '/patient/invoices':
      return (_) => const PatientInvoicesScreen();
    case '/patient/reports':
      return (_) => const MedicalReportsPage();
    case '/patient/medicines':
      return (_) => const MedicinesPage();
    case '/patient/qr':
      return (_) => const QRPage();
    
    // Global Settings
    case '/change-password':
      return (_) => const ChangePasswordScreen();
    case '/settings':
      return (_) => const SettingsScreen();
    
    // Social Media
    case '/social-media':
      return (_) => const SocialMediaPostScreen();
    
    default:
      return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return MaterialApp(
      title: 'Hospital Appointment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: ThemeData.dark(),
      themeMode: appProvider.themeMode,
      locale: appProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Use home property for initial route - NO routes property to avoid conflict
      home: const AuthWrapper(),
      // Use onGenerateRoute for all other routes
      // IMPORTANT: We do NOT use the routes property to avoid conflict with home
      onGenerateRoute: (settings) {
        final routeName = settings.name;
        
        // Handle null or '/' route - all go to AuthWrapper
        if (routeName == null || routeName == '/') {
          return MaterialPageRoute(builder: (_) => const AuthWrapper());
        }
        
        // Handle routes manually to avoid any map evaluation issues
        // Get route builder using a helper function that never includes '/'
        final builder = _getRouteBuilder(routeName);
        
        if (builder != null) {
          // Pass arguments if they exist
          return MaterialPageRoute(
            builder: builder,
            settings: settings,
          );
        }
        
        // Default fallback to AuthWrapper
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      },
    );
  }
}
