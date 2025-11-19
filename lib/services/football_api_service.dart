import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cache_service.dart';
import '../config/league_filter_config.dart';
import '../utils/app_logger.dart';

/// API-Football Service
/// Documentation: https://www.api-football.com/documentation-v3
class FootballApiService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  static const String _apiKey = '91829c7254923be05777fc60f4696d98';
  
  final CacheService _cache = CacheService();

  /// Common headers for all requests
  Map<String, String> get _headers => {
        'x-rapidapi-key': _apiKey,
        'x-rapidapi-host': 'v3.football.api-sports.io',
      };

  /// Check if the error indicates a service outage
  bool _isServiceOutage(int statusCode, String responseBody) {
    // HTTP 5xx errors indicate server-side issues
    if (statusCode >= 500 && statusCode < 600) {
      return true;
    }
    
    // Check for specific Cloudflare errors
    if (responseBody.contains('error code: 5') || 
        responseBody.contains('cloudflare') ||
        responseBody.contains('service unavailable')) {
      return true;
    }
    
    return false;
  }

  /// Create a fallback response for service outages
  Map<String, dynamic> _createFallbackResponse(String endpoint) {
    return {
      'get': endpoint,
      'results': 0,
      'response': [],
      'errors': ['Service temporarily unavailable. Please try again later.'],
      'service_status': 'outage',
      'message': 'API-Football is experiencing technical difficulties. Data will be restored once service is available.'
    };
  }

  /// Test API connection and get account info
  Future<Map<String, dynamic>> getApiStatus() async {
    try {
      AppLogger.debug('Checking API status', data: '$_baseUrl/status');
      AppLogger.verbose('Request headers', data: _headers);
      
      final response = await http.get(
        Uri.parse('$_baseUrl/status'),
        headers: _headers,
      );

      AppLogger.debug('API Status response', data: 'status=${response.statusCode}');
      AppLogger.verbose('Response headers', data: response.headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.info('API Status retrieved successfully');
        return data;
      } else {
        AppLogger.warning('API Status error', data: 'status=${response.statusCode}, reason=${response.reasonPhrase}');
        AppLogger.verbose('Error response body', data: response.body);
        
        // Check if this is a service outage
        if (_isServiceOutage(response.statusCode, response.body)) {
          AppLogger.error('API service outage detected - returning fallback status');
          return {
            'get': 'status',
            'errors': ['Service temporarily unavailable'],
            'response': {
              'account': {'firstname': null, 'lastname': null, 'email': null},
              'subscription': {
                'plan': 'unavailable',
                'end': null,
                'active': false
              },
              'requests': {
                'current': 0,
                'limit_day': 0
              }
            },
            'service_status': 'outage'
          };
        }
        
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            final message = errorData['message'] ?? 'Unknown error';
            throw Exception('API Status Error (${response.statusCode}): $message');
          }
        } catch (parseError) {
          AppLogger.warning('Could not parse error response', error: parseError);
        }
        
        throw Exception('API Status failed: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      AppLogger.error('Exception in getApiStatus', error: e);
      rethrow;
    }
  }

  /// Get live fixtures
  /// Cached for 15 seconds, filtered by allowed leagues only
  Future<Map<String, dynamic>> getLiveFixtures() async {
    final cacheKey = 'football_live_fixtures';
    
    try {
      // Check cache first (15 second TTL for live data)
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      
      // Cache miss - fetch from API
      final url = '$_baseUrl/fixtures?live=all';
      AppLogger.debug('Requesting live fixtures', data: url);
      AppLogger.verbose('API Key', data: '${_apiKey.substring(0, 8)}...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      AppLogger.debug('Live fixtures response', data: 'status=${response.statusCode}');
      AppLogger.verbose('Response headers', data: response.headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Filter matches by allowed leagues and exclude women's leagues
        if (data['response'] is List) {
          final originalMatches = List<Map<String, dynamic>>.from(data['response']);
          final filteredMatches = LeagueFilterConfig.filterMatches(originalMatches);
          
          final stats = LeagueFilterConfig.getFilterStats(originalMatches, filteredMatches);
          AppLogger.info('League filter applied', data: '${stats["original"]} → ${stats["filtered"]} matches (removed ${stats["removed"]}, women: ${stats["womens_removed"]})');
          
          data['response'] = filteredMatches;
          data['results'] = filteredMatches.length;
        }
        
        AppLogger.info('Live fixtures loaded', data: 'results=${data['results']}, errors=${data['errors']}');
        
        // Cache the filtered response (15 second TTL)
        await _cache.set(cacheKey, data, CacheService.ttlLiveMatches);
        
        return data;
      } else {
        AppLogger.warning('Live fixtures error response', data: 'status=${response.statusCode}, content-type=${response.headers['content-type']}');
        AppLogger.verbose('Error response body', data: response.body);
        
        // Check if this is a service outage
        if (_isServiceOutage(response.statusCode, response.body)) {
          AppLogger.error('API service outage detected - returning fallback response');
          return _createFallbackResponse('fixtures');
        }
        
        // Try to parse error response for more details
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            final errors = errorData['errors'] ?? [];
            final message = errorData['message'] ?? 'Unknown error';
            AppLogger.error('API Error details', data: 'message="$message", errors=$errors');
            throw Exception('API Error (${response.statusCode}): $message');
          }
        } catch (parseError) {
          AppLogger.warning('Could not parse error response', error: parseError);
        }
        
        throw Exception('API returned ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      AppLogger.error('Exception in getLiveFixtures', error: e);
      rethrow;
    }
  }

  /// Get fixtures by date
  /// date format: YYYY-MM-DD
  Future<Map<String, dynamic>> getFixturesByDate(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures?date=$date'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Check if this is a service outage
        if (_isServiceOutage(response.statusCode, response.body)) {
          AppLogger.debug('🚫 API service outage detected for fixtures by date');
          return _createFallbackResponse('fixtures');
        }
        throw Exception('Failed to get fixtures: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get fixtures by league and season
  Future<Map<String, dynamic>> getFixturesByLeague({
    required int leagueId,
    required int season,
    int? last, // Get last N fixtures
    int? next, // Get next N fixtures
    String? from, // Date from (YYYY-MM-DD)
    String? to, // Date to (YYYY-MM-DD)
  }) async {
    try {
      var url = '$_baseUrl/fixtures?league=$leagueId&season=$season';
      if (last != null) url += '&last=$last';
      if (next != null) url += '&next=$next';
      if (from != null) url += '&from=$from';
      if (to != null) url += '&to=$to';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get league fixtures: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get team's last fixtures
  Future<Map<String, dynamic>> getTeamLastFixtures({
    required int teamId,
    required int season,
    int last = 5,
  }) async {
    try {
      final url = '$_baseUrl/fixtures?team=$teamId&season=$season&last=$last';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get team fixtures: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get league standings
  Future<Map<String, dynamic>> getStandings({
    required int leagueId,
    required int season,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/standings?league=$leagueId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get standings: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get fixture details by ID
  Future<Map<String, dynamic>> getFixtureById(int fixtureId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures?id=$fixtureId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get fixture: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get leagues list (can filter by country, season, etc.)
  Future<Map<String, dynamic>> getLeagues({
    String? country,
    int? season,
    int? id,
  }) async {
    try {
      var url = '$_baseUrl/leagues?';
      if (country != null) url += 'country=$country&';
      if (season != null) url += 'season=$season&';
      if (id != null) url += 'id=$id&';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get leagues: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get team information
  Future<Map<String, dynamic>> getTeam(int teamId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/teams?id=$teamId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get team: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get head to head matches
  Future<Map<String, dynamic>> getH2H({
    required int team1Id,
    required int team2Id,
    int? last,
  }) async {
    try {
      var url = '$_baseUrl/fixtures/headtohead?h2h=$team1Id-$team2Id';
      if (last != null) url += '&last=$last';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get H2H: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get fixture statistics (lineups, events, statistics)
  Future<Map<String, dynamic>> getFixtureStatistics(int fixtureId) async {
    try {
      final url = '$_baseUrl/fixtures/statistics?fixture=$fixtureId';
      AppLogger.debug('🔍 Requesting statistics: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      AppLogger.debug('📥 Statistics response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('📊 Statistics data: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        AppLogger.debug('❌ Statistics error body: ${response.body}');
        throw Exception('Failed to get statistics: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('❌ Exception in getFixtureStatistics: $e');
      rethrow;
    }
  }

  /// Get fixture events (goals, cards, substitutions)
  Future<Map<String, dynamic>> getFixtureEvents(int fixtureId) async {
    try {
      final url = '$_baseUrl/fixtures/events?fixture=$fixtureId';
      AppLogger.debug('🔍 Requesting events: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      AppLogger.debug('📥 Events response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('📊 Events data: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        AppLogger.debug('❌ Events error body: ${response.body}');
        throw Exception('Failed to get events: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('❌ Exception in getFixtureEvents: $e');
      rethrow;
    }
  }

  /// Get fixture lineups
  Future<Map<String, dynamic>> getFixtureLineups(int fixtureId) async {
    try {
      final url = '$_baseUrl/fixtures/lineups?fixture=$fixtureId';
      AppLogger.debug('🔍 Requesting lineups: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      AppLogger.debug('📥 Lineups response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('📊 Lineups data: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        AppLogger.debug('❌ Lineups error body: ${response.body}');
        throw Exception('Failed to get lineups: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('❌ Exception in getFixtureLineups: $e');
      rethrow;
    }
  }

  /// Get predictions for a fixture
  Future<Map<String, dynamic>> getFixturePredictions(int fixtureId) async {
    try {
      final url = '$_baseUrl/predictions?fixture=$fixtureId';
      AppLogger.debug('🔍 Requesting predictions: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      AppLogger.debug('📥 Predictions response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('📊 Predictions: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        AppLogger.debug('❌ Predictions failed: ${response.statusCode}');
        AppLogger.debug('📄 Response body: ${response.body}');
        
        // Check if this is a service outage
        if (_isServiceOutage(response.statusCode, response.body)) {
          AppLogger.debug('🚫 API service outage detected for predictions - returning fallback');
          return {
            'get': 'predictions',
            'results': 0,
            'response': [],
            'errors': ['Predictions service temporarily unavailable'],
            'service_status': 'outage',
            'message': 'Match predictions will be available once service is restored.'
          };
        }
        
        throw Exception('Failed to get predictions: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('❌ Exception in getFixturePredictions: $e');
      rethrow;
    }
  }

  /// Get top scorers for a league/season
  Future<Map<String, dynamic>> getTopScorers({
    required int leagueId,
    required int season,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/players/topscorers?league=$leagueId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get top scorers: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get top assists for a league/season
  Future<Map<String, dynamic>> getTopAssists({
    required int leagueId,
    required int season,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/players/topassists?league=$leagueId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get top assists: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get top yellow cards for a league/season
  Future<Map<String, dynamic>> getTopYellowCards({
    required int leagueId,
    required int season,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/players/topyellowcards?league=$leagueId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get top yellow cards: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get top red cards for a league/season
  Future<Map<String, dynamic>> getTopRedCards({
    required int leagueId,
    required int season,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/players/topredcards?league=$leagueId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
      throw Exception('Failed to get top red cards: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}

  /// Get player details and statistics
  /// Endpoint: /players?id={playerId}&season={season}
  Future<Map<String, dynamic>> getPlayerDetails({
    required int playerId,
    required int season,
  }) async {
    try {
      AppLogger.debug('🔍 Fetching player details: playerId=$playerId, season=$season');
      final response = await http.get(
        Uri.parse('$_baseUrl/players?id=$playerId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('📥 Player Details API Response: results=${data['results']}');
        return data;
      } else {
        throw Exception('Failed to get player details: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('❌ Error fetching player details: $e');
      rethrow;
    }
  }

  /// Get team squad/roster
  /// Endpoint: /players/squads?team={teamId}
  Future<Map<String, dynamic>> getTeamSquad(int teamId) async {
    try {
      AppLogger.debug('🔍 Fetching team squad: teamId=$teamId');
      final response = await http.get(
        Uri.parse('$_baseUrl/players/squads?team=$teamId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('📥 Team Squad API Response: results=${data['results']}');
        return data;
      } else {
        throw Exception('Failed to get team squad: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('❌ Error fetching team squad: $e');
      rethrow;
    }
  }

  /// Get coach details
  /// Endpoint: /coachs?id={coachId}
  Future<Map<String, dynamic>> getCoachDetails(int coachId) async {
    try {
      AppLogger.debug('🔍 Fetching coach details: coachId=$coachId');
      final response = await http.get(
        Uri.parse('$_baseUrl/coachs?id=$coachId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('📥 Coach Details API Response: results=${data['results']}');
        return data;
      } else {
        throw Exception('Failed to get coach details: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('❌ Error fetching coach details: $e');
      rethrow;
    }
  }
}