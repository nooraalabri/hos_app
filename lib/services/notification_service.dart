import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'email_api.dart';

class NotificationService {
  // Get notification server base URL
  static String get _baseUrl => EmailApiConfig.baseUrl;

  // Send notification and email via notification server
  // The server handles both FCM push notification and email sending
  static Future<void> sendFCMNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final fs = FirebaseFirestore.instance;
      final baseUrl = _baseUrl;
      
      // Get user's FCM token and email
      final userDoc = await fs.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final token = userData?['fcmToken'] as String?;
      final email = userData?['email'] as String?;
      
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No FCM token found for user $userId');
        }
        // Still store the notification in Firestore so it appears in the app
        await _storeNotificationInFirestore(userId, title, body, data, null);
        return;
      }

      // If server URL is not configured, fallback to storing in Firestore only
      if (baseUrl == null || baseUrl.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Notification server URL not configured. Using EmailApiConfig.baseUrl');
          debugPrint('   Make sure notification_server is running on port 3000');
        }
        // Store notification anyway
        await _storeNotificationInFirestore(userId, title, body, data, token);
        return;
      }

      // Prepare payload for notification server
      // Server endpoint: POST /send-notification
      // Expected: { token, email, title, body, data }
      final payload = {
        'token': token,
        'email': email ?? '',
        'title': title,
        'body': body,
        'data': data ?? {},
      };

      // Send to notification server
      final response = await http.post(
        Uri.parse('$baseUrl/send-notification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;
        
        if (kDebugMode) {
          if (success) {
            debugPrint('✅ Notification and email sent successfully to user $userId');
          } else {
            debugPrint('⚠️ Server returned success=false: ${responseData['error']}');
          }
        }
        
        // Store notification in Firestore with sent status
        await _storeNotificationInFirestore(userId, title, body, data, token, sent: success);
      } else {
        if (kDebugMode) {
          debugPrint('❌ Notification server error: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
          debugPrint('   Make sure notification_server is running on port 3000');
        }
        // Store notification anyway (even if server failed)
        await _storeNotificationInFirestore(userId, title, body, data, token, sent: false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending notification via server: $e');
        debugPrint('   Make sure notification_server is running: cd notification_server && npm start');
      }
      // Store notification in Firestore even if sending fails
      try {
        final fs = FirebaseFirestore.instance;
        final userDoc = await fs.collection('users').doc(userId).get();
        final token = userDoc.data()?['fcmToken'] as String?;
        await _storeNotificationInFirestore(userId, title, body, data, token, sent: false);
      } catch (_) {
        // Ignore storage errors
      }
    }
  }

  // Helper method to store notification in Firestore
  static Future<void> _storeNotificationInFirestore(
    String userId,
    String title,
    String body,
    Map<String, dynamic>? data,
    String? token, {
    bool sent = false,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'token': token ?? '',
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'sent': sent,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error storing notification: $e');
      }
    }
  }

  // Legacy method for backward compatibility
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await sendFCMNotification(
      userId: userId,
      title: title,
      body: body,
    );
  }

}
