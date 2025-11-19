import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Analytics Service
/// Unified tracking for Firebase Analytics, Facebook App Events, and TikTok Events API
/// Tracks key events: Login, Register, View Content, and custom events
class AnalyticsService {
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  // TikTok Events API Configuration
  // Get your TikTok Pixel ID and Access Token from TikTok Events Manager
  // https://ads.tiktok.com/marketing_api/docs?id=1701890979375106
  static const String _tiktokPixelId = 'YOUR_TIKTOK_PIXEL_ID'; // TODO: Replace with actual Pixel ID
  static const String _tiktokAccessToken = 'YOUR_TIKTOK_ACCESS_TOKEN'; // TODO: Replace with actual Access Token
  static const String _tiktokApiUrl = 'https://business-api.tiktok.com/open_api/v1.3/event/track/';

  bool _isInitialized = false;

  /// Initialize analytics services
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Analytics already initialized');
      return;
    }

    try {
      print('📊 Initializing Analytics...');

      // Firebase Analytics is automatically initialized with Firebase
      await _firebaseAnalytics.setAnalyticsCollectionEnabled(true);

      // Facebook App Events - automatically initialized
      // No explicit initialization needed for facebook_app_events package

      _isInitialized = true;
      print('✅ Analytics initialized successfully');
      print('   ✓ Firebase Analytics: Ready');
      print('   ✓ Facebook App Events: Ready');
      print('   ℹ️ TikTok Events API: Configure pixel ID and access token');
    } catch (e) {
      print('❌ Error initializing Analytics: $e');
    }
  }

  /// Track user login event
  Future<void> trackLogin({
    required String method, // 'email', 'google', 'anonymous'
    String? userId,
  }) async {
    try {
      print('📊 Tracking Login: method=$method, userId=$userId');

      // Firebase Analytics
      await _firebaseAnalytics.logLogin(loginMethod: method);
      if (userId != null) {
        await _firebaseAnalytics.setUserId(id: userId);
      }

      // Facebook App Events
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_login',
        parameters: {
          'method': method,
          'user_id': userId ?? 'anonymous',
        },
      );

      // TikTok Events API
      await _trackTikTokEvent(
        event: 'Login',
        properties: {
          'method': method,
          'user_id': userId ?? 'anonymous',
        },
      );

      print('✅ Login event tracked successfully');
    } catch (e) {
      print('❌ Error tracking login: $e');
    }
  }

  /// Track user registration event
  Future<void> trackRegistration({
    required String method, // 'email', 'google'
    String? userId,
  }) async {
    try {
      print('📊 Tracking Registration: method=$method, userId=$userId');

      // Firebase Analytics
      await _firebaseAnalytics.logSignUp(signUpMethod: method);
      if (userId != null) {
        await _firebaseAnalytics.setUserId(id: userId);
      }

      // Facebook App Events
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_complete_registration',
        parameters: {
          'method': method,
          'user_id': userId ?? 'unknown',
        },
      );

      // TikTok Events API
      await _trackTikTokEvent(
        event: 'CompleteRegistration',
        properties: {
          'method': method,
          'user_id': userId ?? 'unknown',
        },
      );

      print('✅ Registration event tracked successfully');
    } catch (e) {
      print('❌ Error tracking registration: $e');
    }
  }

  /// Track user logout event
  Future<void> trackLogout({String? userId}) async {
    try {
      print('📊 Tracking Logout: userId=$userId');

      // Firebase Analytics (custom event)
      await _firebaseAnalytics.logEvent(
        name: 'user_logout',
        parameters: {
          'user_id': userId ?? 'anonymous',
        },
      );

      // Remove user ID from Firebase Analytics
      await _firebaseAnalytics.setUserId(id: null);

      // Facebook App Events (custom event)
      await _facebookAppEvents.logEvent(
        name: 'user_logout',
        parameters: {
          'user_id': userId ?? 'anonymous',
        },
      );

      // TikTok Events API
      await _trackTikTokEvent(
        event: 'UserLogout',
        properties: {
          'user_id': userId ?? 'anonymous',
        },
      );

      print('✅ Logout event tracked successfully');
    } catch (e) {
      print('❌ Error tracking logout: $e');
    }
  }

  /// Track view content event (e.g., article view)
  Future<void> trackViewContent({
    required String contentType, // 'article', 'match', 'player', 'team'
    required String contentId,
    String? contentTitle,
    String? contentCategory,
  }) async {
    try {
      print('📊 Tracking ViewContent: type=$contentType, id=$contentId, title=$contentTitle');

      // Firebase Analytics
      await _firebaseAnalytics.logViewItem(
        items: [
          AnalyticsEventItem(
            itemId: contentId,
            itemName: contentTitle ?? contentId,
            itemCategory: contentCategory ?? contentType,
          ),
        ],
        currency: 'IDR',
      );

      // Facebook App Events
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_content_view',
        parameters: {
          'content_type': contentType,
          'content_id': contentId,
          'content_name': contentTitle ?? contentId,
          'content_category': contentCategory ?? contentType,
        },
      );

      // TikTok Events API
      await _trackTikTokEvent(
        event: 'ViewContent',
        properties: {
          'content_type': contentType,
          'content_id': contentId,
          'content_name': contentTitle ?? contentId,
          'content_category': contentCategory ?? contentType,
        },
      );

      print('✅ ViewContent event tracked successfully');
    } catch (e) {
      print('❌ Error tracking view content: $e');
    }
  }

  /// Track search event
  Future<void> trackSearch({
    required String searchTerm,
    String? searchCategory,
  }) async {
    try {
      print('📊 Tracking Search: term=$searchTerm, category=$searchCategory');

      // Firebase Analytics
      await _firebaseAnalytics.logSearch(
        searchTerm: searchTerm,
        parameters: {
          'category': searchCategory ?? 'all',
        },
      );

      // Facebook App Events
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_search',
        parameters: {
          'search_string': searchTerm,
          'content_category': searchCategory ?? 'all',
        },
      );

      // TikTok Events API
      await _trackTikTokEvent(
        event: 'Search',
        properties: {
          'search_string': searchTerm,
          'content_category': searchCategory ?? 'all',
        },
      );

      print('✅ Search event tracked successfully');
    } catch (e) {
      print('❌ Error tracking search: $e');
    }
  }

  /// Track share event
  Future<void> trackShare({
    required String contentType,
    required String contentId,
    required String method, // 'facebook', 'twitter', 'whatsapp', etc.
  }) async {
    try {
      print('📊 Tracking Share: type=$contentType, id=$contentId, method=$method');

      // Firebase Analytics
      await _firebaseAnalytics.logShare(
        contentType: contentType,
        itemId: contentId,
        method: method,
      );

      // Facebook App Events (custom event)
      await _facebookAppEvents.logEvent(
        name: 'content_share',
        parameters: {
          'content_type': contentType,
          'content_id': contentId,
          'method': method,
        },
      );

      // TikTok Events API
      await _trackTikTokEvent(
        event: 'Share',
        properties: {
          'content_type': contentType,
          'content_id': contentId,
          'method': method,
        },
      );

      print('✅ Share event tracked successfully');
    } catch (e) {
      print('❌ Error tracking share: $e');
    }
  }

  /// Track custom event
  Future<void> trackCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      print('📊 Tracking Custom Event: $eventName');

      // Firebase Analytics
      await _firebaseAnalytics.logEvent(
        name: eventName,
        parameters: parameters,
      );

      // Facebook App Events
      await _facebookAppEvents.logEvent(
        name: eventName,
        parameters: parameters ?? {},
      );

      // TikTok Events API
      await _trackTikTokEvent(
        event: eventName,
        properties: parameters ?? {},
      );

      print('✅ Custom event tracked successfully');
    } catch (e) {
      print('❌ Error tracking custom event: $e');
    }
  }

  /// Set user properties for analytics
  Future<void> setUserProperties({
    String? userId,
    String? userType, // 'email', 'google', 'anonymous'
    String? appVersion,
    String? platform,
  }) async {
    try {
      print('📊 Setting User Properties: userId=$userId, userType=$userType');

      // Firebase Analytics
      if (userId != null) {
        await _firebaseAnalytics.setUserId(id: userId);
      }
      if (userType != null) {
        await _firebaseAnalytics.setUserProperty(
          name: 'user_type',
          value: userType,
        );
      }
      if (appVersion != null) {
        await _firebaseAnalytics.setUserProperty(
          name: 'app_version',
          value: appVersion,
        );
      }
      if (platform != null) {
        await _firebaseAnalytics.setUserProperty(
          name: 'platform',
          value: platform,
        );
      }

      // Facebook App Events - Set user ID
      if (userId != null) {
        await _facebookAppEvents.setUserId(userId);
      }

      print('✅ User properties set successfully');
    } catch (e) {
      print('❌ Error setting user properties: $e');
    }
  }

  /// Track TikTok Event via TikTok Events API
  /// Documentation: https://ads.tiktok.com/marketing_api/docs?id=1701890979375106
  Future<void> _trackTikTokEvent({
    required String event,
    Map<String, dynamic>? properties,
  }) async {
    // Skip if not configured
    if (_tiktokPixelId == 'YOUR_TIKTOK_PIXEL_ID' || 
        _tiktokAccessToken == 'YOUR_TIKTOK_ACCESS_TOKEN') {
      print('⚠️ TikTok Events API not configured. Skipping TikTok tracking.');
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final body = {
        'pixel_code': _tiktokPixelId,
        'event': event,
        'timestamp': timestamp.toString(),
        'context': {
          'user_agent': 'BeritaBola/1.0.0 (Flutter)',
          'ip': '', // Server-side: Get user's IP
        },
        'properties': properties ?? {},
      };

      final response = await http.post(
        Uri.parse(_tiktokApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Access-Token': _tiktokAccessToken,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('✅ TikTok event tracked: $event');
      } else {
        print('⚠️ TikTok tracking failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error tracking TikTok event: $e');
      // Don't rethrow - analytics should not crash the app
    }
  }

  /// Get Firebase Analytics instance (for advanced usage)
  FirebaseAnalytics get firebaseAnalytics => _firebaseAnalytics;

  /// Get Facebook App Events instance (for advanced usage)
  FacebookAppEvents get facebookAppEvents => _facebookAppEvents;

  /// Dispose (cleanup)
  void dispose() {
    print('📊 Analytics service disposed');
  }
}
