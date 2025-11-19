import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache Service using Hive for local storage with TTL (Time To Live)
/// Handles API response caching to minimize network calls and respect rate limits
class CacheService {
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Hive box names
  static const String _cacheBoxName = 'api_cache';
  static const String _metaBoxName = 'cache_meta';

  late Box<String> _cacheBox;
  late Box<String> _metaBox;

  bool _isInitialized = false;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      _cacheBox = await Hive.openBox<String>(_cacheBoxName);
      _metaBox = await Hive.openBox<String>(_metaBoxName);
      _isInitialized = true;
      print('✅ CacheService initialized');
    } catch (e) {
      print('❌ Error initializing CacheService: $e');
      rethrow;
    }
  }

  /// Check if cache is initialized
  bool get isInitialized => _isInitialized;

  /// Get cached data with TTL check
  /// Returns null if cache miss or expired
  Future<Map<String, dynamic>?> get(String key) async {
    if (!_isInitialized) {
      print('⚠️ CacheService not initialized');
      return null;
    }

    try {
      // Check if data exists
      final cachedData = _cacheBox.get(key);
      if (cachedData == null) {
        print('📦 Cache miss: $key');
        return null;
      }

      // Check TTL
      final metaData = _metaBox.get(key);
      if (metaData == null) {
        print('⚠️ Cache meta missing for: $key');
        await _cacheBox.delete(key);
        return null;
      }

      final meta = json.decode(metaData);
      final expiryTime = DateTime.parse(meta['expiry']);
      
      if (DateTime.now().isAfter(expiryTime)) {
        print('⏰ Cache expired: $key');
        await _cacheBox.delete(key);
        await _metaBox.delete(key);
        return null;
      }

      print('✅ Cache hit: $key (expires: ${expiryTime.difference(DateTime.now()).inSeconds}s)');
      return json.decode(cachedData);
    } catch (e) {
      print('❌ Error reading cache for $key: $e');
      return null;
    }
  }

  /// Save data to cache with TTL
  /// [key] - Unique cache key
  /// [data] - Data to cache (must be JSON serializable)
  /// [ttlSeconds] - Time to live in seconds
  Future<void> set(String key, Map<String, dynamic> data, int ttlSeconds) async {
    if (!_isInitialized) {
      print('⚠️ CacheService not initialized');
      return;
    }

    try {
      final expiryTime = DateTime.now().add(Duration(seconds: ttlSeconds));
      
      // Save data
      await _cacheBox.put(key, json.encode(data));
      
      // Save metadata
      await _metaBox.put(key, json.encode({
        'expiry': expiryTime.toIso8601String(),
        'created': DateTime.now().toIso8601String(),
      }));

      print('💾 Cached: $key (TTL: ${ttlSeconds}s)');
    } catch (e) {
      print('❌ Error saving cache for $key: $e');
    }
  }

  /// Check if cache exists and is valid (not expired)
  Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// Delete specific cache entry
  Future<void> delete(String key) async {
    if (!_isInitialized) return;

    try {
      await _cacheBox.delete(key);
      await _metaBox.delete(key);
      print('🗑️ Deleted cache: $key');
    } catch (e) {
      print('❌ Error deleting cache for $key: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    if (!_isInitialized) return;

    try {
      await _cacheBox.clear();
      await _metaBox.clear();
      print('🗑️ All cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpired() async {
    if (!_isInitialized) return;

    try {
      final now = DateTime.now();
      final keysToDelete = <String>[];

      for (var key in _metaBox.keys) {
        final metaData = _metaBox.get(key);
        if (metaData != null) {
          final meta = json.decode(metaData);
          final expiryTime = DateTime.parse(meta['expiry']);
          
          if (now.isAfter(expiryTime)) {
            keysToDelete.add(key);
          }
        }
      }

      for (var key in keysToDelete) {
        await _cacheBox.delete(key);
        await _metaBox.delete(key);
      }

      print('🗑️ Cleared ${keysToDelete.length} expired cache entries');
    } catch (e) {
      print('❌ Error clearing expired cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) {
      return {'error': 'Not initialized'};
    }

    try {
      final totalEntries = _cacheBox.length;
      final now = DateTime.now();
      int validEntries = 0;
      int expiredEntries = 0;

      for (var key in _metaBox.keys) {
        final metaData = _metaBox.get(key);
        if (metaData != null) {
          final meta = json.decode(metaData);
          final expiryTime = DateTime.parse(meta['expiry']);
          
          if (now.isAfter(expiryTime)) {
            expiredEntries++;
          } else {
            validEntries++;
          }
        }
      }

      return {
        'total': totalEntries,
        'valid': validEntries,
        'expired': expiredEntries,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// TTL Constants (in seconds)
  static const int ttlLiveMatches = 15; // 15 seconds for live matches
  static const int ttlFinishedMatches = 86400; // 24 hours
  static const int ttlArticleList = 86400; // 24 hours
  static const int ttlArticleSingle = 86400; // 24 hours
  static const int ttlLeagueInfo = 604800; // 7 days
  static const int ttlTeamInfo = 604800; // 7 days
  static const int ttlPlayerStats = 3600; // 1 hour
  static const int ttlHeadToHead = 86400; // 24 hours
}
