import 'package:http/http.dart' as http;
import 'dart:convert';

/// API-Football Service
/// Documentation: https://www.api-football.com/documentation-v3
class FootballApiService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  static const String _apiKey = '91829c7254923be05777fc60f4696d98';

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
      print('🔍 Checking API status: $_baseUrl/status');
      print('🔑 Headers: $_headers');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/status'),
        headers: _headers,
      );

      print('📥 API Status response: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ API Status data: $data');
        return data;
      } else {
        print('❌ API Status error response: ${response.body}');
        print('❌ Response reason: ${response.reasonPhrase}');
        
        // Check if this is a service outage
        if (_isServiceOutage(response.statusCode, response.body)) {
          print('🚫 Detected API service outage - returning fallback status');
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
          print('❌ Could not parse error response: $parseError');
        }
        
        throw Exception('API Status failed: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Exception in getApiStatus: $e');
      rethrow;
    }
  }

  /// Get live fixtures
  Future<Map<String, dynamic>> getLiveFixtures() async {
    try {
      final url = '$_baseUrl/fixtures?live=all';
      print('🔍 Requesting live fixtures: $url');
      print('🔑 API Key: ${_apiKey.substring(0, 8)}...');
      print('🔑 Headers: $_headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('📥 Live fixtures response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Live fixtures: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        print('❌ Live fixtures error response body: ${response.body}');
        print('❌ Response content-type: ${response.headers['content-type']}');
        
        // Check if this is a service outage
        if (_isServiceOutage(response.statusCode, response.body)) {
          print('🚫 Detected API service outage - returning fallback response');
          return _createFallbackResponse('fixtures');
        }
        
        // Try to parse error response for more details
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            final errors = errorData['errors'] ?? [];
            final message = errorData['message'] ?? 'Unknown error';
            print('❌ API Error details: message="$message", errors=$errors');
            throw Exception('API Error (${response.statusCode}): $message');
          }
        } catch (parseError) {
          print('❌ Could not parse error response: $parseError');
        }
        
        throw Exception('API returned ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Exception in getLiveFixtures: $e');
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
          print('🚫 API service outage detected for fixtures by date');
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
      print('🔍 Requesting statistics: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('📥 Statistics response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Statistics data: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        print('❌ Statistics error body: ${response.body}');
        throw Exception('Failed to get statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getFixtureStatistics: $e');
      rethrow;
    }
  }

  /// Get fixture events (goals, cards, substitutions)
  Future<Map<String, dynamic>> getFixtureEvents(int fixtureId) async {
    try {
      final url = '$_baseUrl/fixtures/events?fixture=$fixtureId';
      print('🔍 Requesting events: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('📥 Events response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Events data: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        print('❌ Events error body: ${response.body}');
        throw Exception('Failed to get events: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getFixtureEvents: $e');
      rethrow;
    }
  }

  /// Get fixture lineups
  Future<Map<String, dynamic>> getFixtureLineups(int fixtureId) async {
    try {
      final url = '$_baseUrl/fixtures/lineups?fixture=$fixtureId';
      print('🔍 Requesting lineups: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('📥 Lineups response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Lineups data: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        print('❌ Lineups error body: ${response.body}');
        throw Exception('Failed to get lineups: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getFixtureLineups: $e');
      rethrow;
    }
  }

  /// Get predictions for a fixture
  Future<Map<String, dynamic>> getFixturePredictions(int fixtureId) async {
    try {
      final url = '$_baseUrl/predictions?fixture=$fixtureId';
      print('🔍 Requesting predictions: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('📥 Predictions response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Predictions: results=${data['results']}, errors=${data['errors']}');
        return data;
      } else {
        print('❌ Predictions failed: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        
        // Check if this is a service outage
        if (_isServiceOutage(response.statusCode, response.body)) {
          print('🚫 API service outage detected for predictions - returning fallback');
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
      print('❌ Exception in getFixturePredictions: $e');
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
      print('🔍 Fetching player details: playerId=$playerId, season=$season');
      final response = await http.get(
        Uri.parse('$_baseUrl/players?id=$playerId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Player Details API Response: results=${data['results']}');
        return data;
      } else {
        throw Exception('Failed to get player details: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching player details: $e');
      rethrow;
    }
  }

  /// Get team squad/roster
  /// Endpoint: /players/squads?team={teamId}
  Future<Map<String, dynamic>> getTeamSquad(int teamId) async {
    try {
      print('🔍 Fetching team squad: teamId=$teamId');
      final response = await http.get(
        Uri.parse('$_baseUrl/players/squads?team=$teamId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Team Squad API Response: results=${data['results']}');
        return data;
      } else {
        throw Exception('Failed to get team squad: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching team squad: $e');
      rethrow;
    }
  }

  /// Get coach details
  /// Endpoint: /coachs?id={coachId}
  Future<Map<String, dynamic>> getCoachDetails(int coachId) async {
    try {
      print('🔍 Fetching coach details: coachId=$coachId');
      final response = await http.get(
        Uri.parse('$_baseUrl/coachs?id=$coachId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Coach Details API Response: results=${data['results']}');
        return data;
      } else {
        throw Exception('Failed to get coach details: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching coach details: $e');
      rethrow;
    }
  }
}