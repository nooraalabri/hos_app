// lib/services/notify_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'email_api.dart';

class NotifyService {
  // قراءة عنوان الـ API من EmailApiConfig
  static String? get _base => EmailApiConfig.baseUrl;

  // ===== 1. إرسال إيميل عام =====
  static Future<void> sendEmail({
    required String to,
    required String subject,
    String? text,
    String? html,
  }) async {
    final base = _base;
    if (base == null || base.isEmpty) {
      debugPrint('NotifyService: baseUrl is null or empty — skipping email.');
      return;
    }

    final uri = Uri.parse('$base/send-email');

    try {
      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'text': text ?? '',
          'html': html ??
              '''
              <html>
                <body style="font-family: Arial, sans-serif; line-height:1.6;">
                  <h3>$subject</h3>
                  <p>${text ?? ''}</p>
                  <p style="color:#888; font-size:13px;">
                    This email was sent automatically by Hospital Appointment System.
                  </p>
                </body>
              </html>
              ''',
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Email successfully sent to $to');
      } else {
        debugPrint(
            'Email sending failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('NotifyService error in sendEmail(): $e');
    }
  }

  // ===== 2. إشعار الهيد أدمن عند تسجيل مستشفى جديد =====
  static Future<void> notifyHeadAdmin(String hospitalName) async {
    final base = _base;
    if (base == null || base.isEmpty) {
      debugPrint('NotifyService: baseUrl is null — cannot notify head admin.');
      return;
    }

    final uri = Uri.parse('$base/notify-headadmin');

    try {
      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hospitalName': hospitalName}),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Notified Head Admin about new hospital: $hospitalName');
      } else {
        debugPrint(
            'Failed to notify Head Admin (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('NotifyService error in notifyHeadAdmin(): $e');
    }
  }

  // ===== 3. إشعار الهوسبيتل أدمن عند تسجيل دكتور جديد =====
  static Future<void> notifyHospAdmin({
    required String doctorName,
    required String hospAdminEmail,
    required String hospitalId,
  }) async {
    final base = _base;
    if (base == null || base.isEmpty) {
      debugPrint('NotifyService: baseUrl is null — cannot notify hospital admin.');
      return;
    }

    final uri = Uri.parse('$base/notify-hospadmin');

    try {
      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorName': doctorName,
          'hospAdminEmail': hospAdminEmail,
          'hospitalId': hospitalId,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint(
            'Notified hospital admin ($hospAdminEmail) about doctor: $doctorName');
      } else {
        debugPrint(
            'Failed to notify hospital admin (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('NotifyService error in notifyHospAdmin(): $e');
    }
  }

  // ===== 4. إشعار الدكتور عند قبول/رفض طلبه =====
  static Future<void> notifyDoctorDecision({
    required String toEmail,
    required String doctorName,
    required String hospitalName,
    required bool approved,
  }) async {
    final subject = approved
        ? 'Your Doctor Account Has Been Approved'
        : 'Your Doctor Account Has Been Rejected';

    final text = approved
        ? 'Dear Dr. $doctorName, your request to join $hospitalName has been approved. You can now log in and start using your account.'
        : 'Dear Dr. $doctorName, unfortunately your request to join $hospitalName has been rejected. If you believe this was a mistake, please contact the hospital administration.';

    final html = '''
    <html>
      <body style="font-family: Arial, sans-serif; line-height:1.6;">
        <h3 style="color:${approved ? '#2E8B57' : '#C0392B'};">$subject</h3>
        <p>$text</p>
        <p style="color:#888; font-size:13px;">
          Regards,<br>
          <b>$hospitalName Administration</b><br>
          Hospital Appointment System
        </p>
      </body>
    </html>
    ''';

    await sendEmail(
      to: toEmail,
      subject: subject,
      text: text,
      html: html,
    );
  }

  // ===== 5. إشعار المستشفى عند قبول/رفضها من الهيد أدمن =====
  static Future<void> notifyHospitalDecision({
    required String toEmail,
    required String hospitalName,
    required bool approved,
  }) async {
    final subject = approved
        ? 'Your Hospital Has Been Approved'
        : 'Your Hospital Has Been Rejected';

    final text = approved
        ? 'Dear $hospitalName, your hospital has been approved by the Head Admin. Welcome to the Hospital Appointment System!'
        : 'Dear $hospitalName, unfortunately your hospital registration was rejected by the Head Admin.';

    final html = '''
    <html>
      <body style="font-family: Arial, sans-serif; line-height:1.6;">
        <h3 style="color:${approved ? '#2E8B57' : '#C0392B'};">$subject</h3>
        <p>$text</p>
        <p style="color:#888; font-size:13px;">
          Regards,<br>
          <b>Head Administration</b><br>
          Hospital Appointment System
        </p>
      </body>
    </html>
    ''';

    await sendEmail(
      to: toEmail,
      subject: subject,
      text: text,
      html: html,
    );
  }
}
