// lib/services/notify_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'email_api.dart';

class NotifyService {
  /// إرسال إيميل عام
  static Future<void> sendEmail({
    required String to,
    required String subject,
    String? text,
    String? html,
  }) async {
    final base = EmailApiConfig.baseUrl;
    if (base == null || base.isEmpty) {
      debugPrint('NotifyService: baseUrl is null/empty — skipping email');
      return;
    }

    final uri = Uri.parse('$base/send-email');

    try {
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'text': text,
          'html': html,
        }),
      ).timeout(const Duration(seconds: 8));
      debugPrint('NotifyService: email queued to $to');
    } catch (e) {
      debugPrint('NotifyService error: $e');
    }
  }

  /// إشعار للهيد أدمن عند تسجيل مستشفى جديد
  static Future<void> notifyHeadAdmin(String hospitalName) async {
    final base = EmailApiConfig.baseUrl;
    if (base == null || base.isEmpty) return;

    final uri = Uri.parse('$base/notify-headadmin');

    try {
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hospitalName': hospitalName}),
      ).timeout(const Duration(seconds: 8));

      debugPrint('NotifyService: notified headadmin for $hospitalName');
    } catch (e) {
      debugPrint('NotifyService error notifyHeadAdmin: $e');
    }
  }

  /// إشعار للهوسبيتل أدمن عند تسجيل دكتور جديد
  static Future<void> notifyHospAdmin({
    required String doctorName,
    required String hospAdminEmail,
    required String hospitalId,
  }) async {
    final base = EmailApiConfig.baseUrl;
    if (base == null || base.isEmpty) return;

    final uri = Uri.parse('$base/notify-hospadmin');

    try {
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorName': doctorName,
          'hospAdminEmail': hospAdminEmail,
          'hospitalId': hospitalId,
        }),
      ).timeout(const Duration(seconds: 8));

      debugPrint('NotifyService: notified hospadmin ($hospAdminEmail) for doctor $doctorName');
    } catch (e) {
      debugPrint('NotifyService error notifyHospAdmin: $e');
    }
  }
}
