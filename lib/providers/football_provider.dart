import 'package:flutter/material.dart';
import 'package:beritabola/models/fixture_model.dart';
import 'package:beritabola/models/standing_model.dart';
import 'package:beritabola/services/football_api_service.dart';

/// Football Provider - State management for football matches and leagues
class FootballProvider with ChangeNotifier {
  final FootballApiService _api = FootballApiService();

  // State variables
  bool _isLoadingLive = false;
  bool _isLoadingToday = false;
  bool _isLoadingUpcoming = false;
  String? _error;

  List<FixtureModel> _liveFixtures = [];
  List<FixtureModel> _todayFixtures = [];
  List<FixtureModel> _upcomingFixtures = [];
  Map<int, List<StandingModel>> _standings = {};

  // Getters
  bool get isLoadingLive => _isLoadingLive;
  bool get isLoadingToday => _isLoadingToday;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  String? get error => _error;
  List<FixtureModel> get liveFixtures => _liveFixtures;
  List<FixtureModel> get todayFixtures => _todayFixtures;
  List<FixtureModel> get upcomingFixtures => _upcomingFixtures;

  /// Get standings for a specific league
  List<StandingModel>? getStandings(int leagueId) => _standings[leagueId];

  /// Fetch live fixtures
  Future<void> fetchLiveFixtures() async {
    _isLoadingLive = true;
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
      } else {
        _liveFixtures = [];
        print('💡 No live fixtures available');
      }
    } catch (e) {
      _error = 'Failed to load live matches';
      print('❌ Error fetching live fixtures: $e');
      _liveFixtures = [];
    } finally {
      _isLoadingLive = false;
      notifyListeners();
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
      
      print('⚠️ No squad data found');
      return [];
    } catch (e) {
      print('❌ Error fetching team squad: $e');
      return [];
    }
  }
}
