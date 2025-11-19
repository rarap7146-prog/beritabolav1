/// League Filter Configuration
/// Whitelist of allowed leagues for API-Football to reduce API calls
/// Excludes all women's football leagues
class LeagueFilterConfig {
  // Singleton pattern
  static final LeagueFilterConfig _instance = LeagueFilterConfig._internal();
  factory LeagueFilterConfig() => _instance;
  LeagueFilterConfig._internal();

  /// Allowed league IDs (men's football only)
  /// Based on API-Football documentation: https://www.api-football.com/documentation-v3
  static const Set<int> allowedLeagueIds = {
    // World Competitions
    1,   // World Cup
    15,  // FIFA Club World Cup
    
    // World Cup Qualifications
    32,  // World Cup - Qualification CONMEBOL
    34,  // World Cup - Qualification UEFA
    35,  // World Cup - Qualification CONCACAF
    36,  // World Cup - Qualification CAF
    37,  // World Cup - Qualification AFC
    38,  // World Cup - Qualification OFC
    
    // Continental Championships
    9,   // Copa America
    27,  // AFC Asian Cup (Piala Asia)
    29,  // Africa Cup of Nations (AFCON)
    
    // Continental Club Competitions
    31,  // CONMEBOL Copa Libertadores
    12,  // CAF Champions League
    26,  // AFC Champions League Elite (Asia Champions)
    1140, // AFC Champions League Two
    
    // European Top Leagues
    39,  // Premier League (England)
    140, // La Liga (Spain)
    78,  // Bundesliga (Germany)
    135, // Serie A (Italy)
    61,  // Ligue 1 (France)
    94,  // Primeira Liga (Portugal)
    88,  // Eredivisie (Netherlands)
    203, // Süper Lig (Turkey)
    235, // Premier League (Russia)
    119, // Superliga (Denmark)
    144, // Jupiler Pro League (Belgium)
    
    // Southeast Asian
    274, // Liga 1 Indonesia
    275, // Liga 2 Indonesia
    
    // Middle East
    301, // UAE Pro League
    307, // Saudi Pro League
    
    // South American
    71,  // Serie A (Brazil)
    128, // Liga Profesional (Argentina)
    
    // European Competitions
    2,   // UEFA Champions League
    3,   // UEFA Europa League
    848, // UEFA Conference League
    5,   // UEFA Nations League
  };

  /// Check if a league is allowed (not women's league)
  static bool isLeagueAllowed(int leagueId) {
    return allowedLeagueIds.contains(leagueId);
  }

  /// Check if a league is women's league (by name)
  static bool isWomensLeague(String leagueName) {
    final lowerName = leagueName.toLowerCase();
    return lowerName.contains('women') || 
           lowerName.contains('feminin') || 
           lowerName.contains('female') ||
           lowerName.contains('dames') ||
           lowerName.contains('féminine');
  }

  /// Filter matches by allowed leagues
  static List<Map<String, dynamic>> filterMatches(List<Map<String, dynamic>> matches) {
    return matches.where((match) {
      try {
        final league = match['league'];
        if (league == null) return false;
        
        final leagueId = league['id'] as int?;
        final leagueName = league['name'] as String? ?? '';
        
        // Check if league ID is in whitelist
        if (leagueId != null && !isLeagueAllowed(leagueId)) {
          return false;
        }
        
        // Exclude women's leagues by name
        if (isWomensLeague(leagueName)) {
          return false;
        }
        
        return true;
      } catch (e) {
        print('⚠️ Error filtering match: $e');
        return false;
      }
    }).toList();
  }

  /// Get league name by ID (for debugging)
  static String getLeagueName(int leagueId) {
    const leagueNames = {
      274: 'Liga 1 Indonesia',
      275: 'Liga 2 Indonesia',
      301: 'UAE Pro League',
      307: 'Saudi Pro League',
      1: 'World Cup',
      15: 'FIFA Club World Cup',
      9: 'Copa America',
      29: 'AFCON',
      26: 'AFC Champions League Elite',
      1140: 'AFC Champions League Two',
      39: 'Premier League',
      140: 'La Liga',
      78: 'Bundesliga',
      135: 'Serie A',
      61: 'Ligue 1',
      94: 'Primeira Liga',
      88: 'Eredivisie',
      203: 'Süper Lig',
      235: 'Premier League Russia',
      119: 'Superliga Denmark',
      144: 'Jupiler Pro League',
      71: 'Serie A Brazil',
      128: 'Liga Profesional Argentina',
      2: 'UEFA Champions League',
      3: 'UEFA Europa League',
      848: 'UEFA Conference League',
      5: 'UEFA Nations League',
    };
    
    return leagueNames[leagueId] ?? 'Unknown League ($leagueId)';
  }

  /// Get statistics about filtered matches
  static Map<String, dynamic> getFilterStats(
    List<Map<String, dynamic>> originalMatches,
    List<Map<String, dynamic>> filteredMatches,
  ) {
    final filtered = originalMatches.length - filteredMatches.length;
    final womensCount = originalMatches.where((m) {
      final leagueName = m['league']?['name'] as String? ?? '';
      return isWomensLeague(leagueName);
    }).length;
    
    return {
      'original': originalMatches.length,
      'filtered': filteredMatches.length,
      'removed': filtered,
      'womens_removed': womensCount,
    };
  }
}
