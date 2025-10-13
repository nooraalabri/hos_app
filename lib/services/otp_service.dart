// lib/services/otp_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';
import 'email_api.dart';

class OtpService {
  static String generate() {
    final n = DateTime.now().millisecondsSinceEpoch % 10000;
    return n.toString().padLeft(4, '0');
  }

  static Future<void> sendOtp({
    required String email,
    Duration ttl = const Duration(minutes: 10),
    String? emailApiBaseUrl,
  }) async {
    final code = generate();

    try {
      await FS.saveOtp(email, code, ttl:ttl);
      debugPrint('OTP saved for $email');
    } on TimeoutException {
      debugPrint('FS.saveOtp timeout — نكمل UX');
    } catch (e, st) {
      debugPrint('FS.saveOtp error: $e\n$st');
    }

    final base = emailApiBaseUrl ?? EmailApiConfig.baseUrl;
    if (base != null && base.isNotEmpty) {
      unawaited(() async {
        try {
          await http
              .post(
            Uri.parse('$base/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'to': email, 'code': code}),
          )
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint('send-otp failed: $e'); // ما يوقف الـ UI
        }
      }());
    }
  }

  static Future<bool> verify(String email, String code) =>
      FS.verifyOtp(email, code);
}
