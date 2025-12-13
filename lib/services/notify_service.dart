// lib/services/notify_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'email_api.dart';

class NotifyService {
  // 🔹 إعداد الإيميل
  static String get _base => EmailApiConfig.baseUrl;

  // 🔹 إعداد Firebase Messaging + الإشعارات المحلية
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  // ==============================
  // 🔔 1. تهيئة الإشعارات
  // ==============================
  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) showNotification(n.title, n.body);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notification opened: ${message.notification?.title}');
    });

    final token = await _messaging.getToken();
    debugPrint('🔑 FCM Token: $token');
  }

  // ==============================
  // 🔔 2. عرض إشعار محلي
  // ==============================
  static Future<void> showNotification(String? title, String? body) async {
    const androidDetails = AndroidNotificationDetails(
      'main_channel',
      'Hospital Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _local.show(0, title ?? 'إشعار جديد', body ?? '', details);
  }

  // ==============================
  // ✉️ 3. إرسال إيميل عام (نفس القديم)
  // ==============================
  static Future<void> sendEmail({
    required String to,
    required String subject,
    String? text,
    String? html,
  }) async {
    final base = _base;
    if (base.isEmpty) {
      debugPrint('NotifyService: baseUrl is empty — skipping email.');
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
        debugPrint('✅ Email successfully sent to $to');
      } else {
        debugPrint(
            '❌ Email sending failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('NotifyService error in sendEmail(): $e');
    }
  }

  // ==============================
  // 4️⃣ إشعارات محددة (HeadAdmin, Doctor, Hospital)
  // ==============================
  static Future<void> notifyHeadAdmin(String hospitalName) async {
    await sendEmail(
      to: 'headadmin@example.com',
      subject: 'Hospital Registration Pending',
      text:
      'A new hospital "$hospitalName" has registered and is awaiting approval.',
    );
  }

  static Future<void> notifyHospAdmin({
    required String doctorName,
    required String hospAdminEmail,
    required String hospitalId,
  }) async {
    await sendEmail(
      to: hospAdminEmail,
      subject: 'New Doctor Registration',
      text:
      'Doctor $doctorName has registered in hospital ID: $hospitalId. Please review and approve.',
    );
  }

  static Future<void> notifyDoctorDecision({
    required String toEmail,
    required String doctorName,
    required String hospitalName,
    required bool approved,
  }) async {
    final subject = approved
        ? 'Your Doctor Account Has Been Approved ✅'
        : 'Your Doctor Account Has Been Rejected ❌';
    final text = approved
        ? 'Dear Dr. $doctorName, your request to join $hospitalName has been approved. You can now log in.'
        : 'Dear Dr. $doctorName, unfortunately your request to join $hospitalName was rejected.';
    await sendEmail(to: toEmail, subject: subject, text: text);
  }

  static Future<void> notifyHospitalDecision({
    required String toEmail,
    required String hospitalName,
    required bool approved,
  }) async {
    final subject = approved
        ? 'Your Hospital Has Been Approved ✅'
        : 'Your Hospital Has Been Rejected ❌';
    final text = approved
        ? 'Dear $hospitalName, your hospital has been approved by the Head Admin.'
        : 'Dear $hospitalName, unfortunately your hospital registration was rejected.';
    await sendEmail(to: toEmail, subject: subject, text: text);
  }

  // ==============================
  // 🔔 5. إرسال إشعار FCM
  // ==============================
  static Future<void> sendFCMNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final fs = FirebaseFirestore.instance;
      final userDoc = await fs.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ No FCM token found for user: $userId');
        return;
      }

      // Send FCM notification via HTTP API
      // Note: This requires a backend server with FCM server key
      // For now, we'll just store it in Firestore notifications collection
      await fs.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      debugPrint('✅ FCM notification stored for user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
    }
  }
}
