// lib/services/facebook_api_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FacebookApiService {
  // Get Facebook configuration from Firestore
  static Future<Map<String, String?>> _getFacebookConfig() async {
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('facebook_config')
          .get();
      
      if (configDoc.exists) {
        final data = configDoc.data();
        return {
          'appId': data?['appId'] as String?,
          'appSecret': data?['appSecret'] as String?,
          'accessToken': data?['accessToken'] as String?,
          'pageId': data?['pageId'] as String?,
        };
      }
      
      return {'appId': null, 'appSecret': null, 'accessToken': null, 'pageId': null};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error getting Facebook config: $e');
      }
      return {'appId': null, 'appSecret': null, 'accessToken': null, 'pageId': null};
    }
  }

  // Get User ID from access token (for posting to personal timeline)
  static Future<String?> _getUserIdFromToken(String accessToken) async {
    try {
      // Get user ID
      final userResponse = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/me?access_token=$accessToken&fields=id'),
      );
      
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final userId = userData['id'] as String?;
        // Ensure userId is not empty
        if (userId != null && userId.toString().trim().isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ Found User ID for timeline posting: $userId');
          }
          return userId.toString().trim();
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to get user ID: ${userResponse.statusCode} - ${userResponse.body}');
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error getting User ID from token: $e');
      }
      return null;
    }
  }

  // Get Page Access Token directly using page ID (fallback method)
  static Future<String?> _getPageAccessTokenDirectly(String userAccessToken, String pageId) async {
    try {
      // Try to get page access token directly
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/$pageId?fields=access_token&access_token=$userAccessToken'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String?;
        if (token != null && token.toString().trim().isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ Got Page Access Token directly');
          }
          return token.toString().trim();
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to get page token directly: ${response.statusCode} - ${response.body}');
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error getting Page Access Token directly: $e');
      }
      return null;
    }
  }

  // Get Page ID and Page Access Token from user access token
  static Future<Map<String, String>?> _getPageInfoFromToken(String accessToken) async {
    try {
      // Get pages associated with this token
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/me/accounts?access_token=$accessToken&fields=id,name,access_token'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['data'] as List?;
        if (pages != null && pages.isNotEmpty) {
          // Return the first page ID and its access token
          final firstPage = pages[0] as Map<String, dynamic>;
          final pageId = firstPage['id'] as String?;
          final pageAccessToken = firstPage['access_token'] as String?;
          
          // Ensure pageId and token are not empty
          if (pageId != null && pageId.toString().trim().isNotEmpty &&
              pageAccessToken != null && pageAccessToken.toString().trim().isNotEmpty) {
            if (kDebugMode) {
              debugPrint('✅ Found Page ID: $pageId');
              debugPrint('✅ Found Page Access Token');
            }
            return {
              'pageId': pageId.toString().trim(),
              'pageAccessToken': pageAccessToken.toString().trim(),
            };
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to get pages: ${response.statusCode} - ${response.body}');
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error getting Page info from token: $e');
      }
      return null;
    }
  }

  // Post to Facebook using Graph API
  static Future<Map<String, dynamic>> postToFacebookPage({
    required String message,
  }) async {
    try {
      // Get Facebook config
      final config = await _getFacebookConfig();
      final accessToken = config['accessToken'];
      final pageIdRaw = config['pageId'];

      if (kDebugMode) {
        debugPrint('🔍 Facebook Config - pageIdRaw: "$pageIdRaw" (type: ${pageIdRaw.runtimeType})');
      }

      if (accessToken == null || accessToken.toString().trim().isEmpty) {
        return {
          'success': false,
          'error': 'Facebook Access Token not configured. Please configure it in Firestore config/facebook_config',
        };
      }

      // Post to Facebook Page - get page ID and page access token
      String? targetPageId;
      String? pageAccessToken;
      
      // Hardcoded Page ID (Hospital Publisher) - fallback if not in Firestore
      const String hardcodedPageId = '893904310474953';
      
      // Check if pageId is configured in Firestore
      if (pageIdRaw != null) {
        final pageIdStr = pageIdRaw.toString().trim();
        final cleanPageId = pageIdStr.replaceAll('"', '').replaceAll("'", '').trim();
        if (cleanPageId.isNotEmpty) {
          targetPageId = cleanPageId;
          if (kDebugMode) {
            debugPrint('✅ Using Page ID from config: "$targetPageId"');
          }
        }
      }
      
      // If no page ID in config, try to get it from token
      if (targetPageId == null || targetPageId.isEmpty) {
        if (kDebugMode) {
          debugPrint('🔍 No Page ID in config, fetching from token...');
        }
        final pageInfo = await _getPageInfoFromToken(accessToken.toString());
        if (pageInfo != null) {
          targetPageId = pageInfo['pageId'];
          pageAccessToken = pageInfo['pageAccessToken'];
          if (kDebugMode) {
            debugPrint('✅ Found Page ID: "$targetPageId"');
            debugPrint('✅ Found Page Access Token');
          }
        }
      }
      
      // Fallback to hardcoded page ID if nothing found
      if (targetPageId == null || targetPageId.isEmpty) {
        targetPageId = hardcodedPageId;
        if (kDebugMode) {
          debugPrint('✅ Using hardcoded Page ID: "$targetPageId" (Hospital Publisher)');
        }
      }
      
      // If we have pageId but no pageAccessToken, try to get it directly
      if (targetPageId != null && targetPageId.isNotEmpty && pageAccessToken == null) {
        if (kDebugMode) {
          debugPrint('🔍 Getting Page Access Token directly for Page ID: $targetPageId');
        }
        pageAccessToken = await _getPageAccessTokenDirectly(accessToken.toString(), targetPageId);
      }
      
      // Use page access token if available, otherwise use user token (may not work)
      final tokenToUse = pageAccessToken ?? accessToken.toString();
      
      if (pageAccessToken == null && kDebugMode) {
        debugPrint('⚠️ Using User Access Token instead of Page Access Token - may not work for posting');
      }
      
      if (kDebugMode) {
        debugPrint('📋 Posting to Page ID: "$targetPageId"');
        debugPrint('📋 Using ${pageAccessToken != null ? "Page" : "User"} Access Token');
      }
      
      // Post to Facebook Page
      final graphUrl = 'https://graph.facebook.com/v18.0/$targetPageId/feed';
      
      if (kDebugMode) {
        debugPrint('📤 Posting to Facebook Page: $graphUrl');
      }
      
      final response = await http.post(
        Uri.parse(graphUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'access_token': tokenToUse,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final postId = responseData['id'] as String?;
        
        if (kDebugMode) {
          debugPrint('✅ Facebook post successful: $postId');
        }

        // Cache the page ID and access token if we fetched them
        if (pageAccessToken != null && targetPageId != null) {
          await FirebaseFirestore.instance
              .collection('config')
              .doc('facebook_config')
              .set({
            'pageId': targetPageId,
            'pageAccessToken': pageAccessToken, // Store page token separately if needed
          }, SetOptions(merge: true));
          if (kDebugMode) {
            debugPrint('✅ Cached Page ID: $targetPageId');
          }
        }

        return {
          'success': true,
          'postId': postId,
          'message': 'Post published successfully to Facebook!',
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Failed to post to Facebook';
        
        if (kDebugMode) {
          debugPrint('❌ Facebook API error: ${response.statusCode} - $errorMessage');
          debugPrint('Response: ${response.body}');
        }

        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error posting to Facebook: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Setup Facebook configuration in Firestore
  // Call this once to configure your Facebook credentials
  static Future<void> setupFacebookConfig({
    required String appId,
    required String appSecret,
    required String accessToken,
    String? pageId, // Optional - will be auto-detected if not provided
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('config')
          .doc('facebook_config')
          .set({
        'appId': appId,
        'appSecret': appSecret,
        'accessToken': accessToken,
        'pageId': pageId ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If page ID not provided, try to get it from token
      if (pageId == null || pageId.isEmpty) {
        final pageInfo = await _getPageInfoFromToken(accessToken);
        if (pageInfo != null && pageInfo['pageId'] != null) {
          await FirebaseFirestore.instance
              .collection('config')
              .doc('facebook_config')
              .update({
            'pageId': pageInfo['pageId']!,
          });
          if (kDebugMode) {
            debugPrint('✅ Auto-detected Page ID: ${pageInfo['pageId']}');
          }
        }
      }
      
      if (kDebugMode) {
        debugPrint('✅ Facebook config saved to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving Facebook config: $e');
      }
      rethrow;
    }
  }

  // Check if Facebook is configured
  static Future<bool> isConfigured() async {
    final config = await _getFacebookConfig();
    final accessToken = config['accessToken'];
    return accessToken != null && accessToken.isNotEmpty;
  }
}

