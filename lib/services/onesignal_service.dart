import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'deep_link_service.dart';

/// OneSignal Push Notification Service
/// Handles initialization, notification clicks, and user preferences
class OneSignalService {
  // Singleton pattern
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeepLinkService _deepLinkService = DeepLinkService();

  // OneSignal App ID 
  static const String _appId = 'd798fc3a-3f21-4197-8035-b9098d6e0070';

  bool _isInitialized = false;

  /// Initialize OneSignal
  /// Call this after Firebase initialization
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ OneSignal already initialized');
      return;
    }

    try {
      print('🔔 Initializing OneSignal...');

      // Remove this method to stop OneSignal Debugging
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize OneSignal
      OneSignal.initialize(_appId);

      // Request notification permission (iOS)
      await OneSignal.Notifications.requestPermission(true);

      // Listen to notification clicks
      OneSignal.Notifications.addClickListener(_handleNotificationClick);

      // Listen to notification received (foreground)
      OneSignal.Notifications.addForegroundWillDisplayListener(_handleNotificationReceived);

      // Set external user ID (Firebase UID)
      final user = _auth.currentUser;
      if (user != null && !user.isAnonymous) {
        await setExternalUserId(user.uid);
      }

      _isInitialized = true;
      print('✅ OneSignal initialized successfully');
    } catch (e) {
      print('❌ Error initializing OneSignal: $e');
    }
  }

  /// Handle notification click (when user taps on notification)
  void _handleNotificationClick(OSNotificationClickEvent event) {
    print('🔔 Notification clicked');
    
    try {
      final notification = event.notification;
      final additionalData = notification.additionalData;
      
      if (additionalData != null) {
        print('📦 Notification data: $additionalData');
        
        // Check for deep link URL
        if (additionalData.containsKey('url')) {
          final url = additionalData['url'] as String;
          print('🔗 Opening deep link: $url');
          _deepLinkService.handleDeepLinkManually(url);
          return;
        }
        
        // Check for article ID
        if (additionalData.containsKey('article_id')) {
          final articleId = additionalData['article_id'].toString();
          final url = 'https://beritabola.app/article/$articleId';
          print('📰 Opening article: $url');
          _deepLinkService.handleDeepLinkManually(url);
          return;
        }
        
        // Check for match ID
        if (additionalData.containsKey('match_id')) {
          final matchId = additionalData['match_id'].toString();
          // TODO: Implement match deep link when match detail route is ready
          print('⚽ Match ID: $matchId (route not implemented yet)');
          return;
        }
      }
      
      // No specific action, just log
      print('ℹ️ Notification has no action data');
    } catch (e) {
      print('❌ Error handling notification click: $e');
    }
  }

  /// Handle notification received in foreground
  void _handleNotificationReceived(OSNotificationWillDisplayEvent event) {
    print('🔔 Notification received in foreground');
    
    try {
      final notification = event.notification;
      print('📬 Title: ${notification.title}');
      print('📬 Body: ${notification.body}');
      
      // Notification will be displayed automatically
      // No need to call complete() in OneSignal v5
    } catch (e) {
      print('❌ Error handling notification received: $e');
    }
  }

  /// Set external user ID (Firebase UID)
  /// This allows you to send notifications to specific users
  Future<void> setExternalUserId(String userId) async {
    try {
      await OneSignal.login(userId);
      print('✅ OneSignal external user ID set: $userId');
      
      // Update Firestore with OneSignal player ID
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null) {
        await _updateOneSignalPlayerId(userId, playerId);
      }
    } catch (e) {
      print('❌ Error setting external user ID: $e');
    }
  }

  /// Remove external user ID (on logout)
  Future<void> removeExternalUserId() async {
    try {
      await OneSignal.logout();
      print('✅ OneSignal external user ID removed');
    } catch (e) {
      print('❌ Error removing external user ID: $e');
    }
  }

  /// Enable push notifications
  Future<void> enableNotifications() async {
    try {
      await OneSignal.User.pushSubscription.optIn();
      await _updateNotificationPreference(true);
      print('✅ Push notifications enabled');
    } catch (e) {
      print('❌ Error enabling notifications: $e');
      rethrow;
    }
  }

  /// Disable push notifications
  Future<void> disableNotifications() async {
    try {
      await OneSignal.User.pushSubscription.optOut();
      await _updateNotificationPreference(false);
      print('✅ Push notifications disabled');
    } catch (e) {
      print('❌ Error disabling notifications: $e');
      rethrow;
    }
  }

  /// Check if notifications are enabled
  bool get areNotificationsEnabled {
    try {
      return OneSignal.User.pushSubscription.optedIn ?? false;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  /// Get OneSignal player ID
  String? get playerId {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (e) {
      print('❌ Error getting player ID: $e');
      return null;
    }
  }

  /// Update notification preference in Firestore
  Future<void> _updateNotificationPreference(bool enabled) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) return;

      await _firestore.collection('users').doc(user.uid).update({
        'notificationSubscribed': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification preference updated in Firestore: $enabled');
    } catch (e) {
      print('❌ Error updating notification preference: $e');
    }
  }

  /// Update OneSignal player ID in Firestore
  Future<void> _updateOneSignalPlayerId(String userId, String playerId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'oneSignalPlayerId': playerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ OneSignal player ID updated in Firestore');
    } catch (e) {
      print('❌ Error updating OneSignal player ID: $e');
    }
  }

  /// Send tags to OneSignal for user segmentation
  /// Example: User preferences, favorite teams, etc.
  Future<void> setTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      print('✅ OneSignal tags set: $tags');
    } catch (e) {
      print('❌ Error setting tags: $e');
    }
  }

  /// Remove tags from OneSignal
  Future<void> removeTags(List<String> keys) async {
    try {
      OneSignal.User.removeTags(keys);
      print('✅ OneSignal tags removed: $keys');
    } catch (e) {
      print('❌ Error removing tags: $e');
    }
  }

  /// Get notification permission status
  Future<bool> getNotificationPermission() async {
    try {
      final permission = await OneSignal.Notifications.permission;
      return permission;
    } catch (e) {
      print('❌ Error getting notification permission: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      final accepted = await OneSignal.Notifications.requestPermission(true);
      print('✅ Notification permission: $accepted');
      return accepted;
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Dispose (cleanup)
  void dispose() {
    // OneSignal handles cleanup automatically
    print('🔔 OneSignal service disposed');
  }
}
