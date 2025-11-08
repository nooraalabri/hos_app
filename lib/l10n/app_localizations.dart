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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
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

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

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
  /// **'Phone number'**
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

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

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

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

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

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

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

  /// No description provided for @notifications_settings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notifications_settings;

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

  /// No description provided for @thank_you.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using our app!'**
  String get thank_you;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
