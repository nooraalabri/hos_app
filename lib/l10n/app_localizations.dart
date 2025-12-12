import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @enterAddressManually.
  ///
  /// In en, this message translates to:
  /// **'Enter address manually'**
  String get enterAddressManually;

  /// No description provided for @pickDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get pickDateRange;

  /// No description provided for @medicineNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get medicineNotes;

  /// No description provided for @daysPassed.
  ///
  /// In en, this message translates to:
  /// **'Days passed'**
  String get daysPassed;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @cannotCreatePastShift.
  ///
  /// In en, this message translates to:
  /// **'You cannot create a shift in the past'**
  String get cannotCreatePastShift;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcome_back;

  /// No description provided for @search_patient.
  ///
  /// In en, this message translates to:
  /// **'Search by patient name'**
  String get search_patient;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @manage_shifts.
  ///
  /// In en, this message translates to:
  /// **'Manage Shifts'**
  String get manage_shifts;

  /// No description provided for @filter_by_date.
  ///
  /// In en, this message translates to:
  /// **'Filter by date range'**
  String get filter_by_date;

  /// No description provided for @clear_filters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clear_filters;

  /// No description provided for @add_shift.
  ///
  /// In en, this message translates to:
  /// **'Add shift'**
  String get add_shift;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @select_date.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get select_date;

  /// No description provided for @select_time.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get select_time;

  /// No description provided for @fill_all_fields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields'**
  String get fill_all_fields;

  /// No description provided for @end_time_error.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get end_time_error;

  /// No description provided for @shift_added.
  ///
  /// In en, this message translates to:
  /// **'Shift added'**
  String get shift_added;

  /// No description provided for @shift_deleted.
  ///
  /// In en, this message translates to:
  /// **'Shift deleted'**
  String get shift_deleted;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get error;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @delete_shift.
  ///
  /// In en, this message translates to:
  /// **'Delete shift'**
  String get delete_shift;

  /// No description provided for @delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this shift?'**
  String get delete_confirm;

  /// No description provided for @search_doctor_or_spec.
  ///
  /// In en, this message translates to:
  /// **'Search by doctor / specialization'**
  String get search_doctor_or_spec;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signup;

  /// No description provided for @fullname.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullname;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @specialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specialization;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @hospital_name.
  ///
  /// In en, this message translates to:
  /// **'Hospital name'**
  String get hospital_name;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @doctor_profile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctor_profile;

  /// No description provided for @hospital_profile.
  ///
  /// In en, this message translates to:
  /// **'Hospital Profile'**
  String get hospital_profile;

  /// No description provided for @patient_profile.
  ///
  /// In en, this message translates to:
  /// **'Patient Profile'**
  String get patient_profile;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @my_shifts.
  ///
  /// In en, this message translates to:
  /// **'My Shifts'**
  String get my_shifts;

  /// No description provided for @weekly_shifts.
  ///
  /// In en, this message translates to:
  /// **'Weekly Shifts'**
  String get weekly_shifts;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @add_report.
  ///
  /// In en, this message translates to:
  /// **'Add Report'**
  String get add_report;

  /// No description provided for @medical_record.
  ///
  /// In en, this message translates to:
  /// **'Medical Record'**
  String get medical_record;

  /// No description provided for @medicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicines;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @save_report.
  ///
  /// In en, this message translates to:
  /// **'Save Report'**
  String get save_report;

  /// No description provided for @view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @light_mode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get light_mode;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @reset_password.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reset_password;

  /// No description provided for @enter_code.
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enter_code;

  /// No description provided for @send_code.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get send_code;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @code_sent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email'**
  String get code_sent;

  /// No description provided for @invalid_code.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalid_code;

  /// No description provided for @password_reset_success.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get password_reset_success;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalid_email;

  /// No description provided for @required_field.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get required_field;

  /// No description provided for @weak_password.
  ///
  /// In en, this message translates to:
  /// **'Weak password'**
  String get weak_password;

  /// No description provided for @passwords_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwords_not_match;

  /// No description provided for @error_occurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error_occurred;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get try_again;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @no_data.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get no_data;

  /// No description provided for @welcome_doctor.
  ///
  /// In en, this message translates to:
  /// **'Welcome Doctor'**
  String get welcome_doctor;

  /// No description provided for @welcome_patient.
  ///
  /// In en, this message translates to:
  /// **'Welcome Patient'**
  String get welcome_patient;

  /// No description provided for @welcome_admin.
  ///
  /// In en, this message translates to:
  /// **'Welcome Admin'**
  String get welcome_admin;

  /// No description provided for @pending_approval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pending_approval;

  /// No description provided for @appointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointment;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @book_appointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get book_appointment;

  /// No description provided for @appointment_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmed'**
  String get appointment_confirmed;

  /// No description provided for @appointment_success.
  ///
  /// In en, this message translates to:
  /// **'Your appointment has been booked successfully!'**
  String get appointment_success;

  /// No description provided for @today_appointments.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Appointments'**
  String get today_appointments;

  /// No description provided for @weekly_appointments.
  ///
  /// In en, this message translates to:
  /// **'Weekly Appointments'**
  String get weekly_appointments;

  /// No description provided for @patient_name.
  ///
  /// In en, this message translates to:
  /// **'Patient Name'**
  String get patient_name;

  /// No description provided for @doctor_name.
  ///
  /// In en, this message translates to:
  /// **'Doctor Name'**
  String get doctor_name;

  /// No description provided for @hospital_admin.
  ///
  /// In en, this message translates to:
  /// **'Hospital Admin'**
  String get hospital_admin;

  /// No description provided for @head_admin.
  ///
  /// In en, this message translates to:
  /// **'Head Admin'**
  String get head_admin;

  /// No description provided for @add_hospital.
  ///
  /// In en, this message translates to:
  /// **'Add Hospital'**
  String get add_hospital;

  /// No description provided for @hospital_list.
  ///
  /// In en, this message translates to:
  /// **'Hospital List'**
  String get hospital_list;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @select_role.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get select_role;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @hospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get hospital;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @otp_code.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otp_code;

  /// No description provided for @resend_code.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resend_code;

  /// No description provided for @no_appointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments today'**
  String get no_appointments;

  /// No description provided for @view_report.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get view_report;

  /// No description provided for @add_review.
  ///
  /// In en, this message translates to:
  /// **'Add Review'**
  String get add_review;

  /// No description provided for @star_rating.
  ///
  /// In en, this message translates to:
  /// **'Star Rating'**
  String get star_rating;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @book_now.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get book_now;

  /// No description provided for @hospital_details.
  ///
  /// In en, this message translates to:
  /// **'Hospital Details'**
  String get hospital_details;

  /// No description provided for @doctor_details.
  ///
  /// In en, this message translates to:
  /// **'Doctor Details'**
  String get doctor_details;

  /// No description provided for @search_hospital.
  ///
  /// In en, this message translates to:
  /// **'Search Hospital'**
  String get search_hospital;

  /// No description provided for @search_doctor.
  ///
  /// In en, this message translates to:
  /// **'Search Doctor'**
  String get search_doctor;

  /// No description provided for @search_specialization.
  ///
  /// In en, this message translates to:
  /// **'Search Specialization'**
  String get search_specialization;

  /// No description provided for @view_qr.
  ///
  /// In en, this message translates to:
  /// **'View QR'**
  String get view_qr;

  /// No description provided for @scan_qr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scan_qr;

  /// No description provided for @qr_info.
  ///
  /// In en, this message translates to:
  /// **'Scan QR to view patient information'**
  String get qr_info;

  /// No description provided for @generate_qr.
  ///
  /// In en, this message translates to:
  /// **'Generate QR'**
  String get generate_qr;

  /// No description provided for @qr_generated.
  ///
  /// In en, this message translates to:
  /// **'QR code generated successfully'**
  String get qr_generated;

  /// No description provided for @manageShifts.
  ///
  /// In en, this message translates to:
  /// **'Manage Shifts'**
  String get manageShifts;

  /// No description provided for @filterByDateRange.
  ///
  /// In en, this message translates to:
  /// **'Filter by date range'**
  String get filterByDateRange;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @addShift.
  ///
  /// In en, this message translates to:
  /// **'Add shift'**
  String get addShift;

  /// No description provided for @headAdmin.
  ///
  /// In en, this message translates to:
  /// **'Head Admin'**
  String get headAdmin;

  /// No description provided for @reviewHospitals.
  ///
  /// In en, this message translates to:
  /// **'Review Hospitals'**
  String get reviewHospitals;

  /// No description provided for @hospitalAdmin.
  ///
  /// In en, this message translates to:
  /// **'Hospital Admin'**
  String get hospitalAdmin;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @hospitalProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hospital info & about'**
  String get hospitalProfileSubtitle;

  /// No description provided for @myStaff.
  ///
  /// In en, this message translates to:
  /// **'My Staff'**
  String get myStaff;

  /// No description provided for @myStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage doctors & details'**
  String get myStaffSubtitle;

  /// No description provided for @reportsOverview.
  ///
  /// In en, this message translates to:
  /// **'Weekly / Monthly / Yearly'**
  String get reportsOverview;

  /// No description provided for @addDoctor.
  ///
  /// In en, this message translates to:
  /// **'Add doctor'**
  String get addDoctor;

  /// No description provided for @reviewHospitalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept or reject new hospital requests'**
  String get reviewHospitalsSubtitle;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View each hospital details and statistics'**
  String get reportsSubtitle;

  /// No description provided for @myAppointments.
  ///
  /// In en, this message translates to:
  /// **'My appointments'**
  String get myAppointments;

  /// No description provided for @noAppointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments for today'**
  String get noAppointments;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @myMedicines.
  ///
  /// In en, this message translates to:
  /// **'My medicines'**
  String get myMedicines;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @noMedicines.
  ///
  /// In en, this message translates to:
  /// **'No medicines found.'**
  String get noMedicines;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @searchAndBook.
  ///
  /// In en, this message translates to:
  /// **'Search & Book'**
  String get searchAndBook;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by hospital, specialization, doctor, or location...'**
  String get searchHint;

  /// No description provided for @hospitalTab.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get hospitalTab;

  /// No description provided for @specialisationTab.
  ///
  /// In en, this message translates to:
  /// **'Specialisation'**
  String get specialisationTab;

  /// No description provided for @addOrUpdateReport.
  ///
  /// In en, this message translates to:
  /// **'Add / Update Report'**
  String get addOrUpdateReport;

  /// No description provided for @generalReport.
  ///
  /// In en, this message translates to:
  /// **'General Report'**
  String get generalReport;

  /// No description provided for @writeDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Write diagnosis or general notes'**
  String get writeDiagnosis;

  /// No description provided for @reportRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write the report'**
  String get reportRequired;

  /// No description provided for @patientMedicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Patient Medical Information'**
  String get patientMedicalInfo;

  /// No description provided for @chronicDiseasesHint.
  ///
  /// In en, this message translates to:
  /// **'Chronic diseases (separate by comma)'**
  String get chronicDiseasesHint;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @medicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicine;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @reportAddUpdate.
  ///
  /// In en, this message translates to:
  /// **'Add / Update Report'**
  String get reportAddUpdate;

  /// No description provided for @generalReportHint.
  ///
  /// In en, this message translates to:
  /// **'Write diagnosis or general notes'**
  String get generalReportHint;

  /// No description provided for @generalReportRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the report'**
  String get generalReportRequired;

  /// No description provided for @chronicHint.
  ///
  /// In en, this message translates to:
  /// **'Chronic diseases (separate with commas)'**
  String get chronicHint;

  /// No description provided for @allergyHint.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergyHint;

  /// No description provided for @medicineSection.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get medicineSection;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicineName;

  /// No description provided for @medicineDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get medicineDosage;

  /// No description provided for @medicineDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get medicineDays;

  /// No description provided for @medicineNameHint.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medicineNameHint;

  /// No description provided for @medicineDosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2× daily'**
  String get medicineDosageHint;

  /// No description provided for @medicineDaysHint.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get medicineDaysHint;

  /// No description provided for @medicineNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get medicineNotesHint;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @previousReports.
  ///
  /// In en, this message translates to:
  /// **'Previous Reports'**
  String get previousReports;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get noReports;

  /// No description provided for @noDetails.
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get noDetails;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @saveReport.
  ///
  /// In en, this message translates to:
  /// **'Save Report'**
  String get saveReport;

  /// No description provided for @saveReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report saved successfully'**
  String get saveReportSuccess;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get errorPrefix;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @dosageExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2× daily'**
  String get dosageExample;

  /// No description provided for @daysExample.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get daysExample;

  /// No description provided for @noPreviousReports.
  ///
  /// In en, this message translates to:
  /// **'No previous reports found.'**
  String get noPreviousReports;

  /// No description provided for @reportSaved.
  ///
  /// In en, this message translates to:
  /// **'Report saved successfully'**
  String get reportSaved;

  /// No description provided for @doctorTab.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorTab;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @viewDoctors.
  ///
  /// In en, this message translates to:
  /// **'View Doctors'**
  String get viewDoctors;

  /// No description provided for @tapSeeDoctors.
  ///
  /// In en, this message translates to:
  /// **'Tap to see doctors in this field'**
  String get tapSeeDoctors;

  /// No description provided for @seeDoctors.
  ///
  /// In en, this message translates to:
  /// **'See Doctors'**
  String get seeDoctors;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noDoctorsForHospital.
  ///
  /// In en, this message translates to:
  /// **'No doctors found for \"{name}\"'**
  String noDoctorsForHospital(Object name);

  /// No description provided for @noDoctorsForSpec.
  ///
  /// In en, this message translates to:
  /// **'No doctors found for \"{spec}\"'**
  String noDoctorsForSpec(Object spec);

  /// No description provided for @specialisation.
  ///
  /// In en, this message translates to:
  /// **'Specialisation'**
  String get specialisation;

  /// No description provided for @viewShifts.
  ///
  /// In en, this message translates to:
  /// **'View Shifts'**
  String get viewShifts;

  /// No description provided for @noShifts.
  ///
  /// In en, this message translates to:
  /// **'No shifts found'**
  String get noShifts;

  /// No description provided for @slotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'slots available'**
  String slotsAvailable(Object count);

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @confirmBookingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Book {doctor} on {date} at {time}?'**
  String confirmBookingQuestion(Object date, Object doctor, Object time);

  /// No description provided for @alreadyBookedToday.
  ///
  /// In en, this message translates to:
  /// **'You already have an appointment with {doctor} today.'**
  String alreadyBookedToday(Object doctor);

  /// No description provided for @slotBooked.
  ///
  /// In en, this message translates to:
  /// **'This time is already booked. Please choose another slot.'**
  String get slotBooked;

  /// No description provided for @appointmentBooked.
  ///
  /// In en, this message translates to:
  /// **'Appointment booked for {time} with {doctor}'**
  String appointmentBooked(Object doctor, Object time);

  /// No description provided for @errorBooking.
  ///
  /// In en, this message translates to:
  /// **'Error booking: {err}'**
  String errorBooking(Object err);

  /// No description provided for @patientQr.
  ///
  /// In en, this message translates to:
  /// **'Patient QR Code'**
  String get patientQr;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code to view patient profile'**
  String get scanQr;

  /// No description provided for @patientIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Patient ID not found'**
  String get patientIdNotFound;

  /// No description provided for @civilMustBe8Digits.
  ///
  /// In en, this message translates to:
  /// **'Civil number must be exactly 8 digits'**
  String get civilMustBe8Digits;

  /// No description provided for @phoneMustStartWith7or9.
  ///
  /// In en, this message translates to:
  /// **'Phone number must start with 7 or 9 and be 8 digits'**
  String get phoneMustStartWith7or9;

  /// No description provided for @weightHeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Weight and height must be positive numbers with max 3 digits'**
  String get weightHeightInvalid;

  /// No description provided for @dob7days.
  ///
  /// In en, this message translates to:
  /// **'Date of birth must be at least 7 days before today'**
  String get dob7days;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'User profile not found'**
  String get profileNotFound;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @medicalInfoDoctorOnly.
  ///
  /// In en, this message translates to:
  /// **'Medical Information (Doctor only)'**
  String get medicalInfoDoctorOnly;

  /// No description provided for @showQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get showQr;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @civilNumber.
  ///
  /// In en, this message translates to:
  /// **'Civil Number'**
  String get civilNumber;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dob;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get height;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// No description provided for @chronicDiseases.
  ///
  /// In en, this message translates to:
  /// **'Chronic Diseases'**
  String get chronicDiseases;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @editPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Personal Information'**
  String get editPersonalInfo;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @appointmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get appointmentCancelled;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @hospitalName.
  ///
  /// In en, this message translates to:
  /// **'Hospital Name'**
  String get hospitalName;

  /// No description provided for @medicalReports.
  ///
  /// In en, this message translates to:
  /// **'Medical reports'**
  String get medicalReports;

  /// No description provided for @appointmentDay.
  ///
  /// In en, this message translates to:
  /// **'Appointment day'**
  String get appointmentDay;

  /// No description provided for @noAvailableShifts.
  ///
  /// In en, this message translates to:
  /// **'No available shifts'**
  String get noAvailableShifts;

  /// No description provided for @rescheduledTo.
  ///
  /// In en, this message translates to:
  /// **'Appointment rescheduled to'**
  String get rescheduledTo;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly / Monthly / Yearly overview'**
  String get dashboardSubtitle;

  /// No description provided for @shiftAdded.
  ///
  /// In en, this message translates to:
  /// **'Shift added'**
  String get shiftAdded;

  /// No description provided for @shiftUpdated.
  ///
  /// In en, this message translates to:
  /// **'Shift updated'**
  String get shiftUpdated;

  /// No description provided for @shiftDeleted.
  ///
  /// In en, this message translates to:
  /// **'Shift deleted'**
  String get shiftDeleted;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this shift?'**
  String get deleteConfirm;

  /// No description provided for @searchDoctorOrSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Search by doctor or specialization'**
  String get searchDoctorOrSpecialization;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @completeAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields'**
  String get completeAllFields;

  /// No description provided for @endTimeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeAfterStart;

  /// No description provided for @weekdayName.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get weekdayName;

  /// No description provided for @notifications_settings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notifications_settings;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @profileImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Profile Image URL (optional)'**
  String get profileImageUrl;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get saveSuccess;

  /// No description provided for @fillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields.'**
  String get fillRequired;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile:'**
  String get saveError;

  /// No description provided for @medicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Medical Record'**
  String get medicalRecord;

  /// No description provided for @medicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get medicalInfo;

  /// No description provided for @updateMedicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Update Medical Record'**
  String get updateMedicalRecord;

  /// No description provided for @medicalRecordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Medical record updated successfully'**
  String get medicalRecordUpdated;

  /// No description provided for @todaysAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Appointments'**
  String get todaysAppointments;

  /// No description provided for @addUpdateReport.
  ///
  /// In en, this message translates to:
  /// **'Add / Update Report'**
  String get addUpdateReport;

  /// No description provided for @new_appointment.
  ///
  /// In en, this message translates to:
  /// **'New Appointment'**
  String get new_appointment;

  /// No description provided for @appointment_reminder.
  ///
  /// In en, this message translates to:
  /// **'Appointment Reminder'**
  String get appointment_reminder;

  /// No description provided for @appointment_completed.
  ///
  /// In en, this message translates to:
  /// **'Appointment Completed'**
  String get appointment_completed;

  /// No description provided for @doctor_reviewed.
  ///
  /// In en, this message translates to:
  /// **'Doctor Reviewed'**
  String get doctor_reviewed;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report Details'**
  String get reportDetails;

  /// No description provided for @reportDate.
  ///
  /// In en, this message translates to:
  /// **'Report Date'**
  String get reportDate;

  /// No description provided for @hospital_approval_requests.
  ///
  /// In en, this message translates to:
  /// **'Hospital Approval Requests'**
  String get hospital_approval_requests;

  /// No description provided for @no_pending_hospitals.
  ///
  /// In en, this message translates to:
  /// **'No pending hospital requests'**
  String get no_pending_hospitals;

  /// No description provided for @license_number.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get license_number;

  /// No description provided for @cr_number.
  ///
  /// In en, this message translates to:
  /// **'Commercial Reg. No'**
  String get cr_number;

  /// No description provided for @location_label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location_label;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @created_at.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get created_at;

  /// No description provided for @image_not_available.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get image_not_available;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfile;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @myShifts.
  ///
  /// In en, this message translates to:
  /// **'My Shifts'**
  String get myShifts;

  /// No description provided for @weeklyShifts.
  ///
  /// In en, this message translates to:
  /// **'Weekly Shifts'**
  String get weeklyShifts;

  /// No description provided for @doctorMenu.
  ///
  /// In en, this message translates to:
  /// **'Doctor Menu'**
  String get doctorMenu;

  /// No description provided for @doctorDetails.
  ///
  /// In en, this message translates to:
  /// **'Doctor details'**
  String get doctorDetails;

  /// No description provided for @enterRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Enter recovery code'**
  String get enterRecoveryCode;

  /// No description provided for @invalidOrExpired.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get invalidOrExpired;

  /// No description provided for @hintCode.
  ///
  /// In en, this message translates to:
  /// **'----'**
  String get hintCode;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot\npassword'**
  String get forgotPasswordTitle;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter valid email'**
  String get enterValidEmail;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code. Try again.'**
  String get failedToSend;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @hospitalsApproved.
  ///
  /// In en, this message translates to:
  /// **'Hospitals (approved)'**
  String get hospitalsApproved;

  /// No description provided for @hospitalsPending.
  ///
  /// In en, this message translates to:
  /// **'Hospitals (pending)'**
  String get hospitalsPending;

  /// No description provided for @doctorsApproved.
  ///
  /// In en, this message translates to:
  /// **'Doctors (approved)'**
  String get doctorsApproved;

  /// No description provided for @doctorsPending.
  ///
  /// In en, this message translates to:
  /// **'Doctors (pending)'**
  String get doctorsPending;

  /// No description provided for @patientsTotal.
  ///
  /// In en, this message translates to:
  /// **'Patients (total)'**
  String get patientsTotal;

  /// No description provided for @newUsers.
  ///
  /// In en, this message translates to:
  /// **'New users'**
  String get newUsers;

  /// No description provided for @newHospitals.
  ///
  /// In en, this message translates to:
  /// **'New hospitals'**
  String get newHospitals;

  /// No description provided for @hospitalsOverview.
  ///
  /// In en, this message translates to:
  /// **'Hospitals Overview'**
  String get hospitalsOverview;

  /// No description provided for @noApprovedHospitals.
  ///
  /// In en, this message translates to:
  /// **'No approved hospitals available'**
  String get noApprovedHospitals;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @hospitalStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get hospitalStats;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @doctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctors;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @editHospital.
  ///
  /// In en, this message translates to:
  /// **'Edit Hospital'**
  String get editHospital;

  /// No description provided for @hospitalDetails.
  ///
  /// In en, this message translates to:
  /// **'Hospital details'**
  String get hospitalDetails;

  /// No description provided for @hospitalReports.
  ///
  /// In en, this message translates to:
  /// **'Hospital Reports'**
  String get hospitalReports;

  /// No description provided for @hospitalOverview.
  ///
  /// In en, this message translates to:
  /// **'Hospital Overview'**
  String get hospitalOverview;

  /// No description provided for @newRegister.
  ///
  /// In en, this message translates to:
  /// **'New register'**
  String get newRegister;

  /// No description provided for @visits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visits;

  /// No description provided for @noDoctors.
  ///
  /// In en, this message translates to:
  /// **'No doctors'**
  String get noDoctors;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deleteDoctor.
  ///
  /// In en, this message translates to:
  /// **'Delete doctor'**
  String get deleteDoctor;

  /// No description provided for @deleteDoctorConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this doctor?'**
  String get deleteDoctorConfirm;

  /// No description provided for @doctorDeleted.
  ///
  /// In en, this message translates to:
  /// **'Doctor deleted'**
  String get doctorDeleted;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your request has been submitted!'**
  String get requestSubmitted;

  /// No description provided for @reviewingRegistration.
  ///
  /// In en, this message translates to:
  /// **'We are reviewing your registration.\nYou will be notified once your request is approved.'**
  String get reviewingRegistration;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as:'**
  String get signedInAs;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @stillPending.
  ///
  /// In en, this message translates to:
  /// **'Still pending. Please try again later.'**
  String get stillPending;

  /// No description provided for @userProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'User profile not found.'**
  String get userProfileNotFound;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApprovalTitle;

  /// No description provided for @registerDoctor.
  ///
  /// In en, this message translates to:
  /// **'Register Doctor'**
  String get registerDoctor;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Valid email required'**
  String get validEmailRequired;

  /// No description provided for @selectHospital.
  ///
  /// In en, this message translates to:
  /// **'Select hospital'**
  String get selectHospital;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordRules.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars incl. upper, lower, number & special'**
  String get passwordRules;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please re-enter password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @noHospitalsFound.
  ///
  /// In en, this message translates to:
  /// **'No approved hospitals found. Please try again later.'**
  String get noHospitalsFound;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @registerHospital.
  ///
  /// In en, this message translates to:
  /// **'Register Hospital'**
  String get registerHospital;

  /// No description provided for @enterOfficialHospitalName.
  ///
  /// In en, this message translates to:
  /// **'Enter official hospital name'**
  String get enterOfficialHospitalName;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// No description provided for @mohLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'MOH license number'**
  String get mohLicenseNumber;

  /// No description provided for @crNumber.
  ///
  /// In en, this message translates to:
  /// **'Commercial Registration Number'**
  String get crNumber;

  /// No description provided for @enterCrNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter CR number'**
  String get enterCrNumber;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter valid number'**
  String get enterValidNumber;

  /// No description provided for @passwordRulesFull.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars, must include upper/lower/number/symbol'**
  String get passwordRulesFull;

  /// No description provided for @addressLocation.
  ///
  /// In en, this message translates to:
  /// **'Address / Location'**
  String get addressLocation;

  /// No description provided for @enterFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full address or Google Maps link'**
  String get enterFullAddress;

  /// No description provided for @websiteOptional.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get websiteOptional;

  /// No description provided for @myName.
  ///
  /// In en, this message translates to:
  /// **'My Name'**
  String get myName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @dobHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get dobHint;

  /// No description provided for @civilMustBe8.
  ///
  /// In en, this message translates to:
  /// **'Must be exactly 8 digits'**
  String get civilMustBe8;

  /// No description provided for @passwordsNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsNotMatch;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset\npassword'**
  String get resetPasswordTitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @reenterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reenterNewPassword;

  /// No description provided for @passwordHintText.
  ///
  /// In en, this message translates to:
  /// **'Password must have at least 8 characters, including upper & lower letters, a number, and a special character.'**
  String get passwordHintText;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// No description provided for @emailResetLink.
  ///
  /// In en, this message translates to:
  /// **'We emailed you a reset link. Please check your inbox.'**
  String get emailResetLink;

  /// No description provided for @noEmailFound.
  ///
  /// In en, this message translates to:
  /// **'No email found for reset.'**
  String get noEmailFound;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @unknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown role'**
  String get unknownRole;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectRole;

  /// No description provided for @roleHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get roleHospital;

  /// No description provided for @roleDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get roleDoctor;

  /// No description provided for @rolePatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get rolePatient;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hospital Appointment'**
  String get welcomeTitle;

  /// No description provided for @acceptReject.
  ///
  /// In en, this message translates to:
  /// **'Accept / Reject'**
  String get acceptReject;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// No description provided for @pickLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick location on map'**
  String get pickLocationOnMap;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @pickFromMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick location from map'**
  String get pickFromMap;

  /// No description provided for @doctorReports.
  ///
  /// In en, this message translates to:
  /// **'Doctor Reports'**
  String get doctorReports;

  /// No description provided for @patientReports.
  ///
  /// In en, this message translates to:
  /// **'Patient Reports'**
  String get patientReports;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @min8chars.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get min8chars;

  /// No description provided for @forgotPasswordQ.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordQ;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user?'**
  String get newUser;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get loginFailed;

  /// No description provided for @noAccountForEmail.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email.'**
  String get noAccountForEmail;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get incorrectPassword;

  /// No description provided for @invalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidCredential;

  /// No description provided for @hospital_approved_msg.
  ///
  /// In en, this message translates to:
  /// **'Hospital has been approved'**
  String get hospital_approved_msg;

  /// No description provided for @hospital_rejected_msg.
  ///
  /// In en, this message translates to:
  /// **'Hospital has been rejected'**
  String get hospital_rejected_msg;

  /// No description provided for @approval_email_subject.
  ///
  /// In en, this message translates to:
  /// **'Hospital Approval'**
  String get approval_email_subject;

  /// No description provided for @approval_email_text.
  ///
  /// In en, this message translates to:
  /// **'Your hospital has been approved by the administration.'**
  String get approval_email_text;

  /// No description provided for @rejection_email_subject.
  ///
  /// In en, this message translates to:
  /// **'Hospital Rejection'**
  String get rejection_email_subject;

  /// No description provided for @rejection_email_text.
  ///
  /// In en, this message translates to:
  /// **'Your hospital registration has been rejected.'**
  String get rejection_email_text;

  /// No description provided for @doctor_approval_requests.
  ///
  /// In en, this message translates to:
  /// **'Doctor Approval Requests'**
  String get doctor_approval_requests;

  /// No description provided for @no_pending_doctors.
  ///
  /// In en, this message translates to:
  /// **'No pending doctor requests'**
  String get no_pending_doctors;

  /// No description provided for @doctor_approved_msg.
  ///
  /// In en, this message translates to:
  /// **'Doctor has been approved'**
  String get doctor_approved_msg;

  /// No description provided for @doctor_rejected_msg.
  ///
  /// In en, this message translates to:
  /// **'Doctor has been rejected'**
  String get doctor_rejected_msg;

  /// No description provided for @approved_email_subject.
  ///
  /// In en, this message translates to:
  /// **'Doctor Account Approved'**
  String get approved_email_subject;

  /// No description provided for @approved_email_text.
  ///
  /// In en, this message translates to:
  /// **'Your account has been approved.'**
  String get approved_email_text;

  /// No description provided for @rejected_email_subject.
  ///
  /// In en, this message translates to:
  /// **'Doctor Account Rejected'**
  String get rejected_email_subject;

  /// No description provided for @rejected_email_text.
  ///
  /// In en, this message translates to:
  /// **'Your account has been rejected.'**
  String get rejected_email_text;

  /// No description provided for @patientReviews.
  ///
  /// In en, this message translates to:
  /// **'Patient Reviews'**
  String get patientReviews;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviews;

  /// No description provided for @noComment.
  ///
  /// In en, this message translates to:
  /// **'No comment provided'**
  String get noComment;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @noAppointmentsInShift.
  ///
  /// In en, this message translates to:
  /// **'No appointments in this shift'**
  String get noAppointmentsInShift;

  /// No description provided for @thank_you.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using our app!'**
  String get thank_you;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
