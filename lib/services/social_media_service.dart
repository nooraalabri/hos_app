import 'package:flutter/foundation.dart';
import 'facebook_api_service.dart';

enum SocialMediaPlatform {
  facebook,
}

class SocialMediaService {
  /// Post to Facebook Page using Graph API (direct posting, no user login required)
  Future<Map<String, dynamic>> postToFacebook({
    required String postText,
    String? userId,
  }) async {
    return await FacebookApiService.postToFacebookPage(
      message: postText,
    );
  }

  /// Main method to post to platform
  Future<Map<String, dynamic>> postToPlatform({
    required SocialMediaPlatform platform,
    required String postText,
    String? imageUrl,
    String? userId,
  }) async {
    switch (platform) {
      case SocialMediaPlatform.facebook:
        return await postToFacebook(
          postText: postText,
          userId: userId,
        );
    }
  }

  /// Check if Facebook is configured
  Future<bool> isPlatformConfigured(SocialMediaPlatform platform) async {
    return await FacebookApiService.isConfigured();
  }
}

