import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

/// Analytics Service
/// Unified tracking for Firebase Analytics and Facebook App Events
/// Tracks key events: Login, Register, View Content, and custom events
class AnalyticsService {
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

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

      // Facebook App Events - Enable advertiser tracking
      await _facebookAppEvents.setAdvertiserTracking(enabled: true);
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      
      print('   → Facebook: setAdvertiserTracking(true)');
      print('   → Facebook: setAutoLogAppEventsEnabled(true)');
      
      // Flush events immediately (for testing)
      await _facebookAppEvents.flush();
      print('   → Facebook: flush() called');

      _isInitialized = true;
      print('✅ Analytics initialized successfully');
      print('   ✓ Firebase Analytics: Ready');
      print('   ✓ Facebook App Events: Ready (Advertiser Tracking Enabled)');
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

      // Facebook App Events - Login (Standard Event)
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_login',
        parameters: {
          'fb_mobile_login_method': method,
        },
      );
      print('   → Facebook: Logged fb_mobile_login event');
      await _facebookAppEvents.flush();
      print('   → Facebook: Events flushed');

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

      // Facebook App Events - CompleteRegistration (Standard Event)
      await _facebookAppEvents.logEvent(
        name: 'CompleteRegistration',
        parameters: {
          'fb_registration_method': method,
          'fb_content_id': userId ?? 'unknown',
        },
      );
      await _facebookAppEvents.flush();

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

      // Facebook App Events - ViewContent (Standard Event)
      await _facebookAppEvents.logEvent(
        name: 'ViewContent',
        parameters: {
          'fb_content_type': contentType,
          'fb_content_id': contentId,
          'fb_content': contentTitle ?? contentId,
        },
      );
      print('   → Facebook: Logged ViewContent event');
      await _facebookAppEvents.flush();
      print('   → Facebook: Events flushed');

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
        parameters: parameters?.cast<String, Object>(),
      );

      // Facebook App Events
      await _facebookAppEvents.logEvent(
        name: eventName,
        parameters: parameters ?? {},
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

      // Note: Facebook App Events in version 0.19.7 doesn't support setUserId()
      // User identification is handled automatically through the SDK

      print('✅ User properties set successfully');
    } catch (e) {
      print('❌ Error setting user properties: $e');
    }
  }

  /// Track app install / first open
  Future<void> trackAppInstall() async {
    try {
      print('📊 Tracking App Install (First Open)');

      // Firebase Analytics - log app open
      await _firebaseAnalytics.logAppOpen();

      // Facebook App Events - App Install (Standard Event)
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_activate_app',
        parameters: {
          'fb_app_events_user_agent': 'beritabola_flutter',
        },
      );
      await _facebookAppEvents.flush();

      print('✅ App Install/First Open tracked successfully');
    } catch (e) {
      print('❌ Error tracking app install: $e');
    }
  }

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      print('📊 Tracking Screen View: $screenName');

      // Firebase Analytics
      await _firebaseAnalytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );

      print('✅ Screen view tracked: $screenName');
    } catch (e) {
      print('❌ Error tracking screen view: $e');
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
