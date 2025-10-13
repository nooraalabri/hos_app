import 'package:flutter/material.dart';
import 'package:hos_app/screens/approve_doctors.dart';
import 'package:hos_app/screens/approve_hospitals.dart';
import 'package:hos_app/screens/pending_approval.dart';
import 'package:hos_app/screens/welcome.dart';
import 'package:hos_app/screens/login_screen.dart';
import 'package:hos_app/screens/role_selection.dart';
import 'package:hos_app/screens/register_patient.dart';
import 'package:hos_app/screens/register_doctor.dart';
import 'package:hos_app/screens/register_hospital.dart';
import 'package:hos_app/screens/forgot_password.dart';
import 'package:hos_app/screens/enter_code.dart';
import 'package:hos_app/screens/reset_password.dart';
import 'package:hos_app/screens/role_router.dart';
import 'package:hos_app/screens/hospital_profile.dart';
import 'package:hos_app/screens/hospital_reports.dart';
import 'package:hos_app/screens/my_staff.dart';
import 'package:hos_app/screens/head_admin_reports.dart';

class AppRoutes {
  static const hospitalProfile = '/hospital-profile';
  static const hospitalReports = '/hospital-reports';
  static const myStaff = '/my-staff';
  static const welcome = '/';
  static const login = '/login';
  static const selectRole = '/select-role';
  static const regPatient = '/register-patient';
  static const regDoctor = '/register-doctor';
  static const regHospital = '/register-hospital';
  static const forgot = '/forgot';
  static const enterCode = '/enter-code';
  static const reset = '/reset';
  static const roleRouter = '/role-router';
  static const approveHospitals = '/approve-hospitals';
  static const approveDoctors = '/approve-doctors';
  static const headAdminReports = '/head-admin-reports';
  static const pendingApproval = '/pending-approval';


  static Map<String, WidgetBuilder> map = {
    hospitalProfile: (_) => const HospitalProfileScreen(),
    hospitalReports: (_) => const HospitalReportsScreen(),
    myStaff: (_) => const MyStaffScreen(),
    welcome: (_) => const WelcomeScreen(),
    login: (_) => const LoginScreen(),
    selectRole: (_) => const RoleSelectionScreen(),
    regPatient: (_) => const RegisterPatientScreen(),
    regDoctor: (_) => const RegisterDoctorScreen(),
    regHospital: (_) => const RegisterHospitalScreen(),
    forgot: (_) => const ForgotPasswordScreen(),
    enterCode: (_) => const EnterCodeScreen(),
    reset: (_) => const ResetPasswordScreen(),
    roleRouter: (_) => const RoleRouter(),
    approveHospitals: (_) => const ApproveHospitalsScreen(),
    approveDoctors: (_) => const ApproveDoctorsScreen(),
    headAdminReports: (_) => const HeadAdminReportsScreen(),
    pendingApproval: (_) => const PendingApprovalScreen(),

  };
}
