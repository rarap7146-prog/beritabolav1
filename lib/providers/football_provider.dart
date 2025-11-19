import 'dart:async';
import 'package:flutter/material.dart';
import 'package:beritabola/models/fixture_model.dart';
import 'package:beritabola/models/standing_model.dart';
import 'package:beritabola/services/football_api_service.dart';
import 'package:beritabola/services/football_websocket_service.dart';

/// Football Provider - State management for football matches and leagues
class FootballProvider with ChangeNotifier {
  final FootballApiService _api = FootballApiService();
  final FootballWebSocketService _websocket = FootballWebSocketService();

  StreamSubscription? _websocketEventSubscription;
  StreamSubscription? _connectionStatusSubscription;
  Timer? _liveMatchRefreshTimer;
  
  // State variables
  bool _isLoadingLive = false;
  bool _isLoadingToday = false;
  bool _isLoadingUpcoming = false;
  bool _isRefreshingLive = false; // For auto-refresh animation
  String? _error;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  List<FixtureModel> _liveFixtures = [];
  List<FixtureModel> _todayFixtures = [];
  List<FixtureModel> _upcomingFixtures = [];
  Map<int, List<StandingModel>> _standings = {};

  // Getters
  bool get isLoadingLive => _isLoadingLive;
  bool get isLoadingToday => _isLoadingToday;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  bool get isRefreshingLive => _isRefreshingLive; // For showing refresh animation
  String? get error => _error;
  List<FixtureModel> get liveFixtures => _liveFixtures;
  List<FixtureModel> get todayFixtures => _todayFixtures;
  List<FixtureModel> get upcomingFixtures => _upcomingFixtures;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isWebSocketConnected => _connectionStatus == ConnectionStatus.connected;

  /// Get standings for a specific league
  List<StandingModel>? getStandings(int leagueId) => _standings[leagueId];

  /// Fetch live fixtures
  Future<void> fetchLiveFixtures({bool isAutoRefresh = false}) async {
    if (isAutoRefresh) {
      _isRefreshingLive = true;
    } else {
      _isLoadingLive = true;
    }
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getLiveFixtures();
      final results = response['results'] as int? ?? 0;

      if (results > 0) {
        final fixturesJson = response['response'] as List;
        _liveFixtures = fixturesJson
            .map((json) => FixtureModel.fromJson(json as Map<String, dynamic>))
            .toList();
        print('💡 Fetched $results live fixtures');
        
        // Start auto-refresh timer if we have live matches
        _startLiveMatchRefreshTimer();
      } else {
        _liveFixtures = [];
        print('💡 No live fixtures available');
        
        // Stop timer if no live matches
        _stopLiveMatchRefreshTimer();
      }
    } catch (e) {
      _error = 'Failed to load live matches';
      print('❌ Error fetching live fixtures: $e');
      _liveFixtures = [];
    } finally {
      _isLoadingLive = false;
      _isRefreshingLive = false;
      notifyListeners();
    }
  }
  
  /// Start auto-refresh timer for live matches (15 seconds interval)
  void _startLiveMatchRefreshTimer() {
    // Cancel existing timer if any
    _liveMatchRefreshTimer?.cancel();
    
    print('⏰ Starting live match auto-refresh timer (15s interval)');
    _liveMatchRefreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      // Only refresh if we have live matches and not already loading
      if (_liveFixtures.isNotEmpty && !_isLoadingLive) {
        print('🔄 Auto-refreshing live matches...');
        await fetchLiveFixtures(isAutoRefresh: true);
      }
    });
  }
  
  /// Stop auto-refresh timer
  void _stopLiveMatchRefreshTimer() {
    if (_liveMatchRefreshTimer != null) {
      print('⏰ Stopping live match auto-refresh timer');
      _liveMatchRefreshTimer?.cancel();
      _liveMatchRefreshTimer = null;
    }
  }

  /// Fetch today's fixtures
  Future<void> fetchTodayFixtures() async {
    _isLoadingToday = true;
    _error = null;
    notifyListeners();

    try {
      final today = DateTime.now();
      final dateStr = _formatDate(today);
      final response = await _api.getFixturesByDate(dateStr);
      final results = response['results'] as int? ?? 0;

      if (results > 0) {
        final fixturesJson = response['response'] as List;
        _todayFixtures = fixturesJson
            .map((json) => FixtureModel.fromJson(json as Map<String, dynamic>))
            .toList();
        print('💡 Fetched $results fixtures for today');
      } else {
        _todayFixtures = [];
        print('💡 No fixtures for today');
      }
    } catch (e) {
      _error = 'Failed to load today\'s matches';
      print('❌ Error fetching today\'s fixtures: $e');
      _todayFixtures = [];
    } finally {
      _isLoadingToday = false;
      notifyListeners();
    }
  }

  /// Fetch upcoming fixtures (next 7 days)
  Future<void> fetchUpcomingFixtures() async {
    _isLoadingUpcoming = true;
    _error = null;
    notifyListeners();

    try {
      final allFixtures = <FixtureModel>[];

      // Fetch fixtures for next 7 days
      for (int i = 1; i <= 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dateStr = _formatDate(date);
        final response = await _api.getFixturesByDate(dateStr);
        final results = response['results'] as int? ?? 0;

        if (results > 0) {
          final fixturesJson = response['response'] as List;
          final fixtures = fixturesJson
              .map((json) => FixtureModel.fromJson(json as Map<String, dynamic>))
              .toList();
          allFixtures.addAll(fixtures);
        }
      }

      _upcomingFixtures = allFixtures;
      print('💡 Fetched ${allFixtures.length} upcoming fixtures (next 7 days)');
    } catch (e) {
      _error = 'Failed to load upcoming matches';
      print('❌ Error fetching upcoming fixtures: $e');
      _upcomingFixtures = [];
    } finally {
      _isLoadingUpcoming = false;
      notifyListeners();
    }
  }

  /// Fetch league standings
  Future<void> fetchStandings(int leagueId, int season) async {
    try {
      final response = await _api.getStandings(
        leagueId: leagueId,
        season: season,
      );
      final results = response['results'] as int? ?? 0;

      if (results > 0) {
        final responseData = response['response'] as List;
        if (responseData.isNotEmpty) {
          final leagueData = responseData[0]['league'] as Map<String, dynamic>;
          final allStandings = leagueData['standings'] as List;

          // Parse all groups (for tournaments) or single group (for leagues)
          final List<StandingModel> combinedStandings = [];
          
          print('🔍 API Response Structure:');
          print('📊 Total groups/standings arrays: ${allStandings.length}');
          
          final Set<String> allGroupNames = {};
          final Map<String, Set<String>> groupTeams = {}; // Track teams per group
          final List<Map<String, dynamic>> groupData = []; // Store group info
          
          // First pass: collect all teams and their groups
          for (int groupIndex = 0; groupIndex < allStandings.length; groupIndex++) {
            final groupStandings = allStandings[groupIndex] as List;
            print('📋 Group Array $groupIndex: ${groupStandings.length} teams');
            
            String? groupName;
            if (groupStandings.isNotEmpty) {
              final firstTeam = groupStandings[0] as Map<String, dynamic>;
              groupName = firstTeam['group']?.toString();
              
              if (groupName != null) {
                allGroupNames.add(groupName);
                groupTeams[groupName] = {};
                
                // Collect all teams in this group
                for (final teamData in groupStandings) {
                  final team = teamData as Map<String, dynamic>;
                  final teamName = team['team']?['name']?.toString() ?? 'Unknown';
                  groupTeams[groupName]!.add(teamName);
                }
                
                groupData.add({
                  'name': groupName,
                  'standings': groupStandings,
                  'teamCount': groupStandings.length,
                });
                
                print('✅ Group Array $groupIndex -> API Group Name: "$groupName"');
                print('   📊 Teams: ${groupTeams[groupName]!.join(", ")}');
              }
            }
          }
          
          // Second pass: detect qualification rounds (teams appearing in multiple groups)
          final Map<String, List<String>> teamAppearances = {};
          for (final entry in groupTeams.entries) {
            final groupName = entry.key;
            final teams = entry.value;
            
            for (final teamName in teams) {
              teamAppearances.putIfAbsent(teamName, () => []);
              teamAppearances[teamName]!.add(groupName);
            }
          }
          
          // Find teams that appear in multiple groups (indicating qualification structure)
          final qualificationTeams = teamAppearances.entries
              .where((entry) => entry.value.length > 1)
              .map((entry) => entry.key)
              .toSet();
          
          if (qualificationTeams.isNotEmpty) {
            print('🎯 QUALIFICATION STRUCTURE DETECTED!');
            print('🔄 Teams appearing in multiple groups: ${qualificationTeams.join(", ")}');
            
            // Identify which groups are qualification rounds
            final Map<String, bool> isQualificationGroup = {};
            for (final groupName in allGroupNames) {
              final groupTeamsList = groupTeams[groupName]!;
              final hasQualificationTeams = groupTeamsList.any((team) => qualificationTeams.contains(team));
              final allTeamsAreQualified = groupTeamsList.every((team) => qualificationTeams.contains(team));
              
              isQualificationGroup[groupName] = hasQualificationTeams && allTeamsAreQualified;
              
              if (isQualificationGroup[groupName] == true) {
                print('🏆 "$groupName" identified as QUALIFICATION ROUND');
              } else {
                print('📍 "$groupName" identified as REGULAR GROUP STAGE');
              }
            }
          }
          
          // Parse all groups with proper labeling
          for (final group in groupData) {
            final groupName = group['name'] as String;
            final groupStandings = group['standings'] as List;
            
            // Determine if this is a qualification round
            final isQualification = qualificationTeams.isNotEmpty && 
                groupTeams[groupName]!.every((team) => qualificationTeams.contains(team));
            
            // Use appropriate label
            final displayName = isQualification ? 'Babak Kualifikasi' : groupName;
            
            final groupTeamModels = groupStandings
                .map((json) => StandingModel.fromJson(
                      json as Map<String, dynamic>, 
                      groupName: displayName
                    ))
                .toList();
            
            combinedStandings.addAll(groupTeamModels);
          }
          
          print('🎯 SUMMARY: Found ${allGroupNames.length} groups: ${allGroupNames.toList().join(", ")}');

          _standings[leagueId] = combinedStandings;

          print('💡 Fetched standings for league $leagueId (${allStandings.length} group(s))');
          notifyListeners();
        }
      } else {
        print('⚠️ No standings found for league $leagueId');
      }
    } catch (e) {
      print('❌ Error fetching standings for league $leagueId: $e');
      // Don't rethrow - set empty standings instead
      _standings[leagueId] = [];
      notifyListeners();
    }
  }

  /// Fetch fixtures for a specific date
  Future<List<FixtureModel>> fetchFixturesByDate(String date) async {
    try {
      final response = await _api.getFixturesByDate(date);
      final results = response['results'] as int? ?? 0;

      if (results > 0) {
        final fixturesJson = response['response'] as List;
        return fixturesJson
            .map((json) => FixtureModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('❌ Error fetching fixtures by date: $e');
      return [];
    }
  }

  /// Fetch fixtures for a specific league
  Future<List<FixtureModel>> fetchLeagueFixtures({
    required int leagueId,
    required int season,
    int? last,
    int? next,
    String? from,
    String? to,
  }) async {
    try {
      print('🔍 Fetching league fixtures: league=$leagueId, season=$season, next=$next, last=$last, from=$from, to=$to');
      final response = await _api.getFixturesByLeague(
        leagueId: leagueId,
        season: season,
        last: last,
        next: next,
        from: from,
        to: to,
      );
      final results = response['results'] as int? ?? 0;
      final errors = response['errors'];
      
      print('📥 API Response: results=$results, errors=$errors');

      if (results > 0) {
        final fixturesJson = response['response'] as List;
        final fixtures = fixturesJson
            .map((json) => FixtureModel.fromJson(json as Map<String, dynamic>))
            .toList();
        print('✅ Parsed ${fixtures.length} fixtures');
        return fixtures;
      }

      print('⚠️ No fixtures returned from API');
      return [];
    } catch (e) {
      print('❌ Error fetching league fixtures: $e');
      return [];
    }
  }

  /// Fetch top scorers for a league/season
  Future<List<Map<String, dynamic>>> fetchTopScorers({
    required int leagueId,
    required int season,
  }) async {
    try {
      print('🔍 Fetching top scorers: league=$leagueId, season=$season');
      final response = await _api.getTopScorers(
        leagueId: leagueId,
        season: season,
      );
      final results = response['results'] as int? ?? 0;
      
      print('📥 API Response: results=$results');

      if (results > 0) {
        final playersJson = response['response'] as List;
        final players = playersJson
            .map((json) => json as Map<String, dynamic>)
            .toList();
        print('✅ Parsed ${players.length} players');
        return players;
      }

      print('⚠️ No players returned from API');
      return [];
    } catch (e) {
      print('❌ Error fetching top scorers: $e');
      return [];
    }
  }

  /// Fetch top assists for a league/season
  Future<List<Map<String, dynamic>>> fetchTopAssists({
    required int leagueId,
    required int season,
  }) async {
    try {
      print('🔍 Fetching top assists: league=$leagueId, season=$season');
      final response = await _api.getTopAssists(
        leagueId: leagueId,
        season: season,
      );
      final results = response['results'] as int? ?? 0;
      
      print('📥 Top Assists API Response: results=$results');
      
      if (results > 0) {
        final playersJson = response['response'] as List;
        return playersJson.map((json) => json as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching top assists: $e');
      return [];
    }
  }

  /// Fetch top yellow cards for a league/season
  Future<List<Map<String, dynamic>>> fetchTopYellowCards({
    required int leagueId,
    required int season,
  }) async {
    try {
      print('🔍 Fetching top yellow cards: league=$leagueId, season=$season');
      final response = await _api.getTopYellowCards(
        leagueId: leagueId,
        season: season,
      );
      final results = response['results'] as int? ?? 0;
      
      print('📥 Top Yellow Cards API Response: results=$results');
      
      if (results > 0) {
        final playersJson = response['response'] as List;
        return playersJson.map((json) => json as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching top yellow cards: $e');
      return [];
    }
  }

  /// Fetch top red cards for a league/season
  Future<List<Map<String, dynamic>>> fetchTopRedCards({
    required int leagueId,
    required int season,
  }) async {
    try {
      print('🔍 Fetching top red cards: league=$leagueId, season=$season');
      final response = await _api.getTopRedCards(
        leagueId: leagueId,
        season: season,
      );
      final results = response['results'] as int? ?? 0;
      
      print('📥 Top Red Cards API Response: results=$results');
      
      if (results > 0) {
        final playersJson = response['response'] as List;
        return playersJson.map((json) => json as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching top red cards: $e');
      return [];
    }
  }

  /// Refresh all data (pull-to-refresh)
  Future<void> refreshAll() async {
    await Future.wait([
      fetchLiveFixtures(),
      fetchTodayFixtures(),
      fetchUpcomingFixtures(),
    ]);
  }

  /// Auto-refresh live fixtures (call every 30-60 seconds)
  Future<void> autoRefreshLive() async {
    if (!_isLoadingLive) {
      await fetchLiveFixtures();
    }
  }

  /// Format date to YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Fetch player details
  Future<Map<String, dynamic>?> fetchPlayerDetails({
    required int playerId,
    required int season,
  }) async {
    try {
      print('🔍 Fetching player details: playerId=$playerId, season=$season');
      final data = await _api.getPlayerDetails(
        playerId: playerId,
        season: season,
      );
      
      final response = data['response'] as List?;
      if (response != null && response.isNotEmpty) {
        print('✅ Player details loaded successfully');
        return response[0] as Map<String, dynamic>;
      }
      
      print('⚠️ No player data found');
      return null;
    } catch (e) {
      print('❌ Error fetching player details: $e');
      return null;
    }
  }

  /// Fetch team information
  Future<Map<String, dynamic>?> fetchTeamInfo(int teamId) async {
    try {
      print('🔍 Fetching team info: teamId=$teamId');
      final data = await _api.getTeam(teamId);
      
      final response = data['response'] as List?;
      if (response != null && response.isNotEmpty) {
        print('✅ Team info loaded successfully');
        return response[0] as Map<String, dynamic>;
      }
      
      print('⚠️ No team data found');
      return null;
    } catch (e) {
      print('❌ Error fetching team info: $e');
      return null;
    }
  }

  /// Fetch team squad
  Future<List<dynamic>> fetchTeamSquad(int teamId) async {
    try {
      print('🔍 Fetching team squad: teamId=$teamId');
      final data = await _api.getTeamSquad(teamId);
      
      final response = data['response'] as List?;
      if (response != null && response.isNotEmpty) {
        final squad = response[0]['players'] as List?;
        print('✅ Team squad loaded: ${squad?.length ?? 0} players');
        return squad ?? [];
      }
      
      print('⚠️ No team squad found');
      return [];
    } catch (e) {
      print('❌ Error fetching team squad: $e');
      return [];
    }
  }

  /// Initialize WebSocket for real-time updates
  Future<void> initializeWebSocket() async {
    try {
      print('⚡ Initializing WebSocket for real-time updates...');
      
      // Connect to WebSocket
      await _websocket.connect();
      
      // Listen to connection status changes
      _connectionStatusSubscription = _websocket.connectionStatus.listen((status) {
        _connectionStatus = status;
        notifyListeners();
        
        if (status == ConnectionStatus.connected) {
          print('✅ WebSocket connected - subscribing to live matches');
          // Subscribe to all live matches when connected
          _websocket.subscribeToAllLive();
        }
      });
      
      // Listen to real-time events
      _websocketEventSubscription = _websocket.events.listen((event) {
        _handleWebSocketEvent(event);
      });
      
      print('✅ WebSocket initialized successfully');
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
    }
  }

  /// Handle real-time WebSocket events
  void _handleWebSocketEvent(Map<String, dynamic> event) {
    try {
      final eventType = event['type'] as String?;
      final fixtureId = event['fixture'] as int?;
      
      if (fixtureId == null) return;

      print('⚡ Real-time event: $eventType for fixture $fixtureId');

      // Find the fixture in our lists
      final liveIndex = _liveFixtures.indexWhere((f) => f.id == fixtureId);
      final todayIndex = _todayFixtures.indexWhere((f) => f.id == fixtureId);

      if (eventType == 'status') {
        // Match status update (halftime, finished, etc.)
        final statusShort = event['status'] as String?;
        final elapsed = event['elapsed'] as int?;
        
        if (liveIndex != -1 && statusShort != null) {
          // Update status in-place by rebuilding the fixture
          final oldFixture = _liveFixtures[liveIndex];
          _liveFixtures[liveIndex] = FixtureModel(
            id: oldFixture.id,
            referee: oldFixture.referee,
            date: oldFixture.date,
            timestamp: oldFixture.timestamp,
            venue: oldFixture.venue,
            city: oldFixture.city,
            status: FixtureStatus(
              long: _mapStatusShortToLong(statusShort),
              short: statusShort,
              elapsed: elapsed,
            ),
            league: oldFixture.league,
            homeTeam: oldFixture.homeTeam,
            awayTeam: oldFixture.awayTeam,
            homeGoals: oldFixture.homeGoals,
            awayGoals: oldFixture.awayGoals,
            halftimeHome: oldFixture.halftimeHome,
            halftimeAway: oldFixture.halftimeAway,
          );
        }
        if (todayIndex != -1 && statusShort != null) {
          final oldFixture = _todayFixtures[todayIndex];
          _todayFixtures[todayIndex] = FixtureModel(
            id: oldFixture.id,
            referee: oldFixture.referee,
            date: oldFixture.date,
            timestamp: oldFixture.timestamp,
            venue: oldFixture.venue,
            city: oldFixture.city,
            status: FixtureStatus(
              long: _mapStatusShortToLong(statusShort),
              short: statusShort,
              elapsed: elapsed,
            ),
            league: oldFixture.league,
            homeTeam: oldFixture.homeTeam,
            awayTeam: oldFixture.awayTeam,
            homeGoals: oldFixture.homeGoals,
            awayGoals: oldFixture.awayGoals,
            halftimeHome: oldFixture.halftimeHome,
            halftimeAway: oldFixture.halftimeAway,
          );
        }
        
        notifyListeners();
        print('📊 Updated match status: $statusShort (${elapsed ?? 0}\')');
      } else if (eventType == 'event') {
        // Match event (goal, card, substitution)
        final eventDetail = event['event'] as String?;
        final homeScore = event['score']?['home'] as int?;
        final awayScore = event['score']?['away'] as int?;
        
        if (homeScore != null && awayScore != null) {
          if (liveIndex != -1) {
            final oldFixture = _liveFixtures[liveIndex];
            _liveFixtures[liveIndex] = FixtureModel(
              id: oldFixture.id,
              referee: oldFixture.referee,
              date: oldFixture.date,
              timestamp: oldFixture.timestamp,
              venue: oldFixture.venue,
              city: oldFixture.city,
              status: oldFixture.status,
              league: oldFixture.league,
              homeTeam: oldFixture.homeTeam,
              awayTeam: oldFixture.awayTeam,
              homeGoals: homeScore,
              awayGoals: awayScore,
              halftimeHome: oldFixture.halftimeHome,
              halftimeAway: oldFixture.halftimeAway,
            );
          }
          if (todayIndex != -1) {
            final oldFixture = _todayFixtures[todayIndex];
            _todayFixtures[todayIndex] = FixtureModel(
              id: oldFixture.id,
              referee: oldFixture.referee,
              date: oldFixture.date,
              timestamp: oldFixture.timestamp,
              venue: oldFixture.venue,
              city: oldFixture.city,
              status: oldFixture.status,
              league: oldFixture.league,
              homeTeam: oldFixture.homeTeam,
              awayTeam: oldFixture.awayTeam,
              homeGoals: homeScore,
              awayGoals: awayScore,
              halftimeHome: oldFixture.halftimeHome,
              halftimeAway: oldFixture.halftimeAway,
            );
          }
          
          notifyListeners();
          print('⚽ Score updated: $homeScore - $awayScore ($eventDetail)');
        }
      }
    } catch (e) {
      print('❌ Error handling WebSocket event: $e');
    }
  }

  /// Map short status codes to long descriptions
  String _mapStatusShortToLong(String short) {
    const statusMap = {
      '1H': 'First Half',
      'HT': 'Halftime',
      '2H': 'Second Half',
      'ET': 'Extra Time',
      'P': 'Penalty',
      'FT': 'Match Finished',
      'AET': 'Match Finished After Extra Time',
      'PEN': 'Match Finished After Penalty',
      'BT': 'Break Time',
      'SUSP': 'Match Suspended',
      'INT': 'Match Interrupted',
      'PST': 'Match Postponed',
      'CANC': 'Match Cancelled',
      'ABD': 'Match Abandoned',
      'AWD': 'Technical Loss',
      'WO': 'WalkOver',
      'LIVE': 'In Progress',
    };
    return statusMap[short] ?? 'Unknown';
  }

  /// Subscribe to specific fixture for real-time updates
  void subscribeToFixture(int fixtureId) {
    _websocket.subscribeToFixture(fixtureId);
  }

  /// Unsubscribe from specific fixture
  void unsubscribeFromFixture(int fixtureId) {
    _websocket.unsubscribeFromFixture(fixtureId);
  }

  /// Disconnect WebSocket
  Future<void> disconnectWebSocket() async {
    await _websocket.disconnect();
    await _websocketEventSubscription?.cancel();
    await _connectionStatusSubscription?.cancel();
    _connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLiveMatchRefreshTimer();
    disconnectWebSocket();
    super.dispose();
  }
}
