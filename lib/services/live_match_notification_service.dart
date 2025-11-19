import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beritabola/models/fixture_model.dart';
import 'package:beritabola/utils/app_logger.dart';

/// Live Match Notification Service
/// Provides sticky notification for tracking selected live match
/// Uses Android Foreground Service for true background updates (15s interval)
class LiveMatchNotificationService {
  // Singleton pattern
  static final LiveMatchNotificationService _instance = LiveMatchNotificationService._internal();
  factory LiveMatchNotificationService() => _instance;
  LiveMatchNotificationService._internal();

  static const _platform = MethodChannel('com.idnkt78.beritabola/foreground_service');
  
  int? _trackedMatchId;
  bool _isInitialized = false;
  
  // Stream controller for tracking state changes
  final _trackingStateController = StreamController<int?>.broadcast();
  Stream<int?> get trackingStateStream => _trackingStateController.stream;

  static const String _prefsKey = 'tracked_live_match_id';

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('Initializing Live Match Notification Service');

      // Restore tracked match if exists
      await _restoreTrackedMatch();

      _isInitialized = true;
      AppLogger.info('Live Match Notification Service initialized');
    } catch (e) {
      AppLogger.error('Error initializing notification service', error: e);
    }
  }

  /// Start tracking a live match
  /// Only one match can be tracked at a time
  Future<void> startTracking(FixtureModel fixture) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // If already tracking another match, stop it first
      if (_trackedMatchId != null && _trackedMatchId != fixture.id) {
        AppLogger.warning('Already tracking match $_trackedMatchId, stopping it first');
        await stopTracking();
        // Small delay to ensure clean service stop
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // If already tracking this match, don't restart
      if (_trackedMatchId == fixture.id) {
        AppLogger.debug('Already tracking this match');
        return;
      }

      AppLogger.info('Starting to track match: ${fixture.homeTeam.name} vs ${fixture.awayTeam.name}');

      _trackedMatchId = fixture.id;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, fixture.id);
      await prefs.setString('${_prefsKey}_data', json.encode(fixture.toJson()));

      // Start Android Foreground Service
      try {
        await _platform.invokeMethod('startService', {'matchId': fixture.id});
        AppLogger.info('Foreground service started', data: 'Match ID: ${fixture.id}');
      } on PlatformException catch (e) {
        AppLogger.error('Failed to start foreground service', error: e.message);
      }

      // Notify listeners
      _trackingStateController.add(fixture.id);

      AppLogger.info('Successfully started tracking match ${fixture.id}');
    } catch (e) {
      AppLogger.error('Error starting match tracking', error: e);
    }
  }

  /// Stop tracking current match
  Future<void> stopTracking() async {
    try {
      AppLogger.info('Stopping match tracking');

      _trackedMatchId = null;

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove('${_prefsKey}_data');

      // Stop Android Foreground Service
      try {
        await _platform.invokeMethod('stopService');
        AppLogger.info('Foreground service stopped');
      } on PlatformException catch (e) {
        AppLogger.error('Failed to stop foreground service', error: e.message);
      }

      // Notify listeners
      _trackingStateController.add(null);

      AppLogger.info('Successfully stopped tracking');
    } catch (e) {
      AppLogger.error('Error stopping tracking', error: e);
    }
  }
  
  /// Sync tracking state from SharedPreferences
  /// Call this to check if service was stopped externally (e.g., from notification)
  Future<void> syncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchId = prefs.getInt(_prefsKey);
      
      if (_trackedMatchId != matchId) {
        _trackedMatchId = matchId;
        _trackingStateController.add(matchId);
        AppLogger.debug('Synced tracking state', data: matchId);
      }
    } catch (e) {
      AppLogger.error('Error syncing tracking state', error: e);
    }
  }

  /// Check if currently tracking a match
  bool get isTracking => _trackedMatchId != null;

  /// Get tracked match ID
  int? get trackedMatchId => _trackedMatchId;
  
  /// Check if a specific match is being tracked
  bool isTrackingMatch(int matchId) => _trackedMatchId == matchId;

  /// Restore tracked match from SharedPreferences (after app restart)
  Future<void> _restoreTrackedMatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchId = prefs.getInt(_prefsKey);

      if (matchId != null) {
        AppLogger.info('Restoring tracked match', data: matchId);
        _trackedMatchId = matchId;

        // Restart foreground service
        try {
          await _platform.invokeMethod('startService', {'matchId': matchId});
          AppLogger.info('Foreground service restarted', data: 'Match ID: $matchId');
        } on PlatformException catch (e) {
          AppLogger.error('Failed to restart foreground service', error: e.message);
        }
      }
    } catch (e) {
      AppLogger.error('Error restoring tracked match', error: e);
    }
  }

  /// Dispose resources
  void dispose() {
    _trackingStateController.close();
  }
}
