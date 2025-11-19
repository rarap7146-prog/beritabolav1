import 'package:beritabola/services/football_api_service.dart';
import 'dart:convert';

/// Quick test to explore API-Football data
/// Run with: dart test/football_api_test.dart
void main() async {
  final api = FootballApiService();
  
  print('=== TESTING API-FOOTBALL ===\n');
  
  // Test 1: API Status
  print('1️⃣ Checking API Status...');
  try {
    final status = await api.getApiStatus();
    print('✅ API Status:');
    print(JsonEncoder.withIndent('  ').convert(status));
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  // Test 2: Live Fixtures
  print('2️⃣ Fetching Live Fixtures...');
  try {
    final live = await api.getLiveFixtures();
    final results = live['results'] ?? 0;
    print('✅ Live Fixtures: $results matches');
    if (results > 0) {
      print(JsonEncoder.withIndent('  ').convert(live));
    } else {
      print('ℹ️ No live matches at the moment');
    }
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  // Test 3: Today's Fixtures
  print('3️⃣ Fetching Today\'s Fixtures...');
  try {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final fixtures = await api.getFixturesByDate(dateStr);
    final results = fixtures['results'] ?? 0;
    print('✅ Today\'s Fixtures ($dateStr): $results matches');
    if (results > 0) {
      final response = fixtures['response'] as List;
      print('First 3 matches:');
      for (var i = 0; i < (results > 3 ? 3 : results); i++) {
        final match = response[i];
        final league = match['league']['name'];
        final homeTeam = match['teams']['home']['name'];
        final awayTeam = match['teams']['away']['name'];
        final status = match['fixture']['status']['short'];
        print('  • $league: $homeTeam vs $awayTeam [$status]');
      }
    } else {
      print('ℹ️ No matches today');
    }
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  // Test 4: Premier League Info (ID: 39) - Check BOTH seasons
  print('4️⃣ Fetching Premier League Info (Season 2024)...');
  try {
    final league = await api.getLeagues(id: 39, season: 2024);
    print('✅ Premier League 2024:');
    print(JsonEncoder.withIndent('  ').convert(league));
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  print('4️⃣b Fetching Premier League Info (Season 2025)...');
  try {
    final league = await api.getLeagues(id: 39, season: 2025);
    print('✅ Premier League 2025:');
    print(JsonEncoder.withIndent('  ').convert(league));
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  // Test 5: Indonesia League Info (ID: 274)
  print('5️⃣ Fetching Liga Indonesia Info...');
  try {
    final league = await api.getLeagues(id: 274, season: 2024);
    print('✅ Liga Indonesia:');
    print(JsonEncoder.withIndent('  ').convert(league));
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  // Test 6: Premier League Standings - Try BOTH seasons
  print('6️⃣ Fetching Premier League Standings (Season 2024)...');
  try {
    final standings = await api.getStandings(leagueId: 39, season: 2024);
    final results = standings['results'] ?? 0;
    print('✅ Standings 2024 found: $results');
    if (results > 0) {
      final response = standings['response'] as List;
      if (response.isNotEmpty) {
        final leagueStandings = response[0]['league']['standings'][0] as List;
        print('Top 5 teams (2024):');
        for (var i = 0; i < (leagueStandings.length > 5 ? 5 : leagueStandings.length); i++) {
          final team = leagueStandings[i];
          final rank = team['rank'];
          final name = team['team']['name'];
          final points = team['points'];
          final played = team['all']['played'];
          print('  $rank. $name - $points pts ($played played)');
        }
      }
    }
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  print('6️⃣b Fetching Premier League Standings (Season 2025)...');
  try {
    final standings = await api.getStandings(leagueId: 39, season: 2025);
    final results = standings['results'] ?? 0;
    print('✅ Standings 2025 found: $results');
    if (results > 0) {
      final response = standings['response'] as List;
      if (response.isNotEmpty) {
        final leagueStandings = response[0]['league']['standings'][0] as List;
        print('Top 5 teams (2025):');
        for (var i = 0; i < (leagueStandings.length > 5 ? 5 : leagueStandings.length); i++) {
          final team = leagueStandings[i];
          final rank = team['rank'];
          final name = team['team']['name'];
          final points = team['points'];
          final played = team['all']['played'];
          print('  $rank. $name - $points pts ($played played)');
        }
      }
    }
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  // Test 7: Premier League Next 5 Fixtures (2025 season)
  print('7️⃣ Fetching Premier League Next 5 Fixtures (Season 2025)...');
  try {
    final fixtures = await api.getFixturesByLeague(
      leagueId: 39,
      season: 2025,
      next: 5,
    );
    final results = fixtures['results'] ?? 0;
    print('✅ Next fixtures: $results');
    if (results > 0) {
      final response = fixtures['response'] as List;
      for (var match in response) {
        final date = match['fixture']['date'];
        final homeTeam = match['teams']['home']['name'];
        final awayTeam = match['teams']['away']['name'];
        print('  • $date: $homeTeam vs $awayTeam');
      }
    }
    print('\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  print('=== TEST COMPLETE ===');
  print('Check the output above to see what data is available.');
  print('Use this info to decide on the best UX approach! 🎯');
}
