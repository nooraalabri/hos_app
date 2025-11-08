import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ========== Doctor Screens ==========
import 'package:hos_app/screens/doctor/add_report_screen.dart';
import 'package:hos_app/screens/doctor/edit_profile.dart';
import 'package:hos_app/screens/doctor/reviews.dart';
import 'package:hos_app/screens/doctor/weekly_shifts_screen.dart';
import 'package:hos_app/screens/doctor/medical_records.dart';
import 'package:hos_app/screens/doctor/my_shifts_screen.dart' as doctor;

// ========== Admin Screens ==========
import 'package:hos_app/admin/manage_shifts_screen.dart' as admin;

// ========== Common Screens ==========
import 'package:hos_app/screens/doctor_home.dart';
import 'package:hos_app/pages/head_admin_home.dart';
import 'package:hos_app/pages/hospital_admin_home.dart';
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
import 'package:hos_app/screens/change_password.dart';
import 'package:hos_app/screens/settings_screen.dart';


// ========== Patient Screens ==========
import 'package:hos_app/patients/patient_home.dart';
import 'package:hos_app/patients/profile_page.dart';
import 'package:hos_app/patients/search_page.dart';
import 'package:hos_app/patients/appointment_page.dart';
import 'package:hos_app/patients/medical_reports_page.dart';
import 'package:hos_app/patients/medicines_page.dart';
import 'package:hos_app/patients/qr_page.dart';

import 'admin/hospital_doctor_reports_screen.dart';
import 'admin/hospital_patient_reports_screen.dart';

class AppRoutes {
  // ========== Hospital & Admin ==========
  static const hospitalProfile = '/hospital-profile';
  static const hospitalReports = '/hospital-reports';
  static const hospitalDoctorReports = '/hospital/doctor-reports';
  static const hospitalPatientReports = '/hospital/patient-reports';
  static const myStaff = '/my-staff';
  static const headAdminReports = '/head-admin-reports';
  static const approveHospitals = '/approve-hospitals';
  static const approveDoctors = '/approve-doctors';
  static const pendingApproval = '/pending-approval';
  static const manageShifts = '/hospital/manage-shifts';
  static const hospitalAppointments = '/hospital/appointments';

  // ========== Auth & Registration ==========
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

  // ========== Home Pages ==========
  static const headAdminHome = '/headadmin/home';
  static const hospitalAdminHome = '/hospitaladmin/home';
  static const doctorHome = '/doctor/home';
  static const patientHome = '/patient/home';

  // ========== Doctor Pages ==========
  static const addReport = '/doctor/add-report';
  static const reviews = '/doctor/reviews';
  static const weeklyShifts = '/doctor/weekly-shifts';
  static const myShifts = '/doctor/my-shifts';
  static const editDoctorProfile = '/doctor/edit-profile';
  static const medicalRecords = '/doctor/medical-records';

  // ========== Patient Pages ==========
  static const patientProfile = '/patient/profile';
  static const patientSearch = '/patient/search';
  static const patientAppointments = '/patient/appointments';
  static const patientReports = '/patient/reports';
  static const patientMedicines = '/patient/medicines';
  static const patientQR = '/patient/qr';

  // ========== Global Settings ==========
  static const changePassword = '/change-password';
  static const settings = '/settings';

  // ========== Route Map ==========
  static Map<String, WidgetBuilder> map = {
    // ---------- Admin & Hospital ----------
    hospitalProfile: (_) => const HospitalProfileScreen(),
    hospitalReports: (_) => const HospitalReportsScreen(),
    hospitalDoctorReports: (_) => const HospitalDoctorReportsScreen(),
    hospitalPatientReports: (_) => const HospitalPatientReportsScreen(),
    myStaff: (_) => const MyStaffScreen(),
    headAdminReports: (_) => const HeadAdminReportsScreen(),
    approveHospitals: (_) => const ApproveHospitalsScreen(),
    approveDoctors: (_) => const ApproveDoctorsScreen(),
    pendingApproval: (_) => const PendingApprovalScreen(),
    manageShifts: (_) => admin.ManageShiftsScreen(),

    // ---------- Auth & Registration ----------
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

    // ---------- Home Pages ----------
    headAdminHome: (_) => const HeadAdminHome(),
    hospitalAdminHome: (_) => const HospitalAdminHome(),
    doctorHome: (_) =>
        DoctorHome(doctorId: FirebaseAuth.instance.currentUser!.uid),
    patientHome: (_) => const PatientHome(),

    // ---------- Doctor Pages ----------
    addReport: (_) => const Placeholder(), // القيم تُمرّر runtime فقط
    reviews: (_) => ReviewsScreen(
        doctorId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown'),
    weeklyShifts: (_) => ShiftsOverviewScreen(
        doctorId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown'),
    myShifts: (_) => doctor.MyShiftsScreen(
        doctorId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown'),
    editDoctorProfile: (_) => EditDoctorProfileScreen(
        doctorId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        currentData: const {}),
    medicalRecords: (_) => MedicalRecord(
      patientId: '',
      appointmentId: '',
      doctorId: '',
    ),

    // ---------- Patient Pages ----------
    patientProfile: (_) => const ProfilePageBody(),
    patientSearch: (_) => const SearchPage(),
    patientAppointments: (_) => const AppointmentPage(),
    patientReports: (_) => const MedicalReportsPage(),
    patientMedicines: (_) => const MedicinesPage(),
    patientQR: (_) => const QRPage(),

    // ---------- Global Settings ----------
    changePassword: (_) => const ChangePasswordScreen(),
    settings: (_) => const SettingsScreen(),
  };
}
