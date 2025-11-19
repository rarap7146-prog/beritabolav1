import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beritabola/providers/football_provider.dart';
import 'package:beritabola/models/standing_model.dart';
import 'package:beritabola/models/fixture_model.dart';

import 'package:beritabola/screens/sports/team_detail_screen.dart';
import 'package:beritabola/screens/sports/match_detail_screen.dart';
import 'package:beritabola/screens/sports/player_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// League Detail Screen - Shows standings, fixtures, and results
class LeagueDetailScreen extends StatefulWidget {
  final int leagueId;
  final String leagueName;
  final int season;

  const LeagueDetailScreen({
    Key? key,
    required this.leagueId,
    required this.leagueName,
    required this.season,
  }) : super(key: key);

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _matchTabController;
  bool _isLoadingStandings = true;
  bool _isLoadingUpcoming = true;
  bool _isLoadingFinished = true;
  bool _isLoadingStats = true;
  String? _selectedGroup; // Currently selected group (null = all groups)
  
  List<dynamic> _upcomingFixtures = [];
  List<dynamic> _finishedFixtures = [];
  List<dynamic> _topScorers = [];
  List<dynamic> _topAssists = [];
  List<dynamic> _topYellowCards = [];
  List<dynamic> _topRedCards = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _matchTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _matchTabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<FootballProvider>(context, listen: false);

    // Load standings
    setState(() => _isLoadingStandings = true);
    try {
      await provider.fetchStandings(widget.leagueId, widget.season);
    } catch (e) {
      print('❌ Error loading standings: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStandings = false);
    }

    // Load upcoming fixtures
    _loadUpcomingMatches();
    
    // Load finished matches
    _loadFinishedMatches();
    
    // Load statistics
    _loadStatistics();
  }

  Future<void> _loadUpcomingMatches() async {
    setState(() => _isLoadingUpcoming = true);
    final provider = Provider.of<FootballProvider>(context, listen: false);
    try {
      // Use API's 'next' parameter to get upcoming fixtures directly
      print('🔍 Fetching upcoming fixtures for league ${widget.leagueId}, season ${widget.season}');
      
      final upcomingMatches = await provider.fetchLeagueFixtures(
        leagueId: widget.leagueId,
        season: widget.season,
        next: 10, // Get next 10 upcoming fixtures
      );
      
      print('🔍 Upcoming fixtures: ${upcomingMatches.length} matches');
      if (upcomingMatches.isNotEmpty) {
        print('📅 First match: ${upcomingMatches[0].homeTeam.name} vs ${upcomingMatches[0].awayTeam.name} on ${upcomingMatches[0].date}');
        print('📊 Status: ${upcomingMatches[0].status.short}');
      }
      if (mounted) {
        setState(() {
          _upcomingFixtures = upcomingMatches;
        });
      }
    } catch (e) {
      print('❌ Error loading upcoming matches: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUpcoming = false);
    }
  }

  Future<void> _loadFinishedMatches() async {
    setState(() => _isLoadingFinished = true);
    final provider = Provider.of<FootballProvider>(context, listen: false);
    try {
      final fixtures = await provider.fetchLeagueFixtures(
        leagueId: widget.leagueId,
        season: widget.season,
        last: 20, // Last 20 matches
      );
      if (mounted) {
        setState(() {
          _finishedFixtures = fixtures;
        });
      }
    } catch (e) {
      print('❌ Error loading finished matches: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFinished = false);
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    final provider = Provider.of<FootballProvider>(context, listen: false);
    try {
      print('🔍 Fetching statistics for league ${widget.leagueId}, season ${widget.season}');
      
      // Fetch all statistics in parallel
      final results = await Future.wait([
        provider.fetchTopScorers(leagueId: widget.leagueId, season: widget.season),
        provider.fetchTopAssists(leagueId: widget.leagueId, season: widget.season),
        provider.fetchTopYellowCards(leagueId: widget.leagueId, season: widget.season),
        provider.fetchTopRedCards(leagueId: widget.leagueId, season: widget.season),
      ]);
      
      if (mounted) {
        setState(() {
          _topScorers = results[0];
          _topAssists = results[1];
          _topYellowCards = results[2];
          _topRedCards = results[3];
        });
      }
      print('✅ Loaded stats:');
      print('   - Top Scorers: ${results[0].length}');
      print('   - Top Assists: ${results[1].length}');
      print('   - Top Yellow Cards: ${results[2].length}');
      print('   - Top Red Cards: ${results[3].length}');
    } catch (e) {
      print('❌ Error loading statistics: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.brightness == Brightness.dark ? Colors.white : theme.primaryColor,
          tabs: const [
            Tab(text: 'Klasemen'),
            Tab(text: 'Pertandingan'),
            Tab(text: 'Statistik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Standings Tab
          _buildStandingsTab(),
          // Matches Tab (with sub-tabs)
          _buildMatchesTab(),
          // Statistics Tab
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildStandingsTab() {
    if (_isLoadingStandings) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<FootballProvider>(
      builder: (context, provider, child) {
        final standings = provider.getStandings(widget.leagueId);

        if (standings == null || standings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline, 
                  size: 64, 
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Colors.grey
                ),
                const SizedBox(height: 16),
                Text(
                  'Klasemen tidak tersedia',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey[600]
                  ),
                ),
              ],
            ),
          );
        }

        // Check if this is a group-based tournament
        final hasGroups = standings.any((s) => s.group != null);
        final availableGroups = hasGroups 
            ? standings.map((s) => s.group).where((g) => g != null).toSet().toList()
            : <String?>[];

        return SingleChildScrollView(
          child: Column(
            children: [
              // Group selector (only show if tournament has groups)
              if (hasGroups) _buildGroupSelector(availableGroups),
              
              // DEBUG: Print qualification zone summary
              if (hasGroups) Builder(builder: (context) {
                print('🎯 QUALIFICATION SUMMARY for ${standings.length} teams:');
                final zonesFound = <String, int>{};
                for (final standing in standings) {
                  if (standing.description != null && standing.description!.isNotEmpty) {
                    final zone = standing.description!;
                    zonesFound[zone] = (zonesFound[zone] ?? 0) + 1;
                  }
                }
                zonesFound.forEach((zone, count) {
                  print('   📍 "$zone" → $count team(s)');
                });
                return const SizedBox.shrink();
              }),
              
              // Single qualification legend (only show once)
              if (hasGroups) _buildCompactQualificationLegend(standings),
              
              // Show separate group sections or filtered single group
              if (_selectedGroup == null && hasGroups)
                // Show all groups separately
                ...availableGroups.map((group) {
                  final groupStandings = standings.where((s) => s.group == group).toList();
                  return _buildGroupSection(group ?? 'Unknown', groupStandings);
                }).toList()
              else
                // Show single selected group or regular league
                _buildSingleGroupView(
                  _selectedGroup == null 
                      ? standings 
                      : standings.where((s) => s.group == _selectedGroup).toList()
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandingRow(StandingModel standing, List<StandingModel> allStandings) {
    final theme = Theme.of(context);
    
    // DEBUG: Log actual API descriptions
    if (standing.description != null) {
      print('🏆 API Description for ${standing.team.name} (Rank ${standing.rank}): "${standing.description}"');
    }
    
    // Get qualification zone color using hybrid detection
    Color? qualificationColor = _getQualificationRowColorHybrid(standing, allStandings, theme);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(team: standing.team),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: qualificationColor,
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade700.withOpacity(0.3)
                : Colors.grey.shade300.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(40),  // Pos
            1: FlexColumnWidth(3),    // Team
            2: FixedColumnWidth(32),  // MP
            3: FixedColumnWidth(28),  // W
            4: FixedColumnWidth(28),  // D
            5: FixedColumnWidth(28),  // L
            6: FixedColumnWidth(38),  // GD
            7: FixedColumnWidth(38),  // Pts
          },
          children: [
            TableRow(
              children: [
                _buildDataCell(standing.rank.toString(), theme, isBold: true),
                _buildTeamCell(standing.team, theme),
                _buildDataCell(standing.matchesPlayed.toString(), theme),
                _buildDataCell(standing.wins.toString(), theme),
                _buildDataCell(standing.draws.toString(), theme),
                _buildDataCell(standing.losses.toString(), theme),
                _buildDataCell(
                  '${standing.goalDifference >= 0 ? "+" : ""}${standing.goalDifference}',
                  theme,
                  textColor: standing.goalDifference > 0 
                      ? Colors.green.shade600 
                      : standing.goalDifference < 0 
                          ? Colors.red.shade600 
                          : null,
                ),
                _buildDataCell(standing.points.toString(), theme, isBold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, ThemeData theme, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: textColor ?? (theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black87),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTeamCell(team, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: team.logo,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) => Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  size: 12,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              team.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Hybrid qualification detection: Position-based + Keyword analysis
  Color? _getQualificationRowColorHybrid(StandingModel standing, List<StandingModel> allStandings, ThemeData theme) {
    if (standing.description == null || standing.description!.isEmpty) return null;
    
    final description = standing.description!;
    final lowerDesc = description.toLowerCase().trim();
    final position = standing.rank;
    final totalTeams = allStandings.length;
    
    // DEBUG: Log what we're checking
    print('🔍 Hybrid check for Rank $position/${totalTeams}: "$lowerDesc"');
    
    // Analyze position in table
    final isTopThird = position <= (totalTeams / 3).ceil(); // Top 33%
    final isBottomQuarter = position > (totalTeams * 0.75); // Bottom 25%
    
    // === STEP 1: Position-based primary detection ===
    
    // BOTTOM positions = Almost always RELEGATION (RED)
    if (isBottomQuarter) {
      print('✅ RED: Bottom position ($position/${totalTeams}) = Relegation');
      return theme.brightness == Brightness.dark
          ? Colors.red.shade900.withOpacity(0.25)
          : Colors.red.shade100.withOpacity(0.7);
    }
    
    // === STEP 2: Keyword-based refinement for TOP positions ===
    
    if (isTopThird) {
      // Check for Europa/Conference League (BLUE/ORANGE)
      if (lowerDesc.contains('europa')) {
        print('✅ BLUE: Top position + Europa keyword');
        return theme.brightness == Brightness.dark
            ? Colors.blue.shade900.withOpacity(0.25)
            : Colors.blue.shade100.withOpacity(0.7);
      }
      
      if (lowerDesc.contains('conference')) {
        print('✅ ORANGE: Top position + Conference keyword');
        return theme.brightness == Brightness.dark
            ? Colors.orange.shade900.withOpacity(0.25)
            : Colors.orange.shade100.withOpacity(0.7);
      }
      
      // Any other description in top positions = Promotion/Champions League (GREEN)
      print('✅ GREEN: Top position ($position/${totalTeams}) with description = Qualification');
      return theme.brightness == Brightness.dark
          ? Colors.green.shade900.withOpacity(0.25)
          : Colors.green.shade100.withOpacity(0.7);
    }
    
    // === STEP 3: Middle positions with descriptions = Playoffs (ORANGE) ===
    print('✅ ORANGE: Middle position ($position/${totalTeams}) = Playoff zone');
    return theme.brightness == Brightness.dark
        ? Colors.orange.shade900.withOpacity(0.25)
        : Colors.orange.shade100.withOpacity(0.7);
  }

  /// Build Statistics Tab with Podium-style Top 3
  Widget _buildStatisticsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasData = _topScorers.isNotEmpty || _topAssists.isNotEmpty || 
                     _topYellowCards.isNotEmpty || _topRedCards.isNotEmpty;

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Statistik tidak tersedia',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Scorers Podium
        if (_topScorers.isNotEmpty) ...[
          _buildCategoryPodium(
            title: 'Pencetak Gol Terbanyak',
            players: _topScorers.take(3).toList(),
            statType: 'goals',
            emoji: '⚽',
          ),
          const SizedBox(height: 24),
        ],
        
        // Top Assists Podium
        if (_topAssists.isNotEmpty) ...[
          _buildCategoryPodium(
            title: 'Assist Terbanyak',
            players: _topAssists.take(3).toList(),
            statType: 'assists',
            emoji: '🎯',
          ),
          const SizedBox(height: 24),
        ],
        
        // Top Yellow Cards
        if (_topYellowCards.isNotEmpty) ...[
          _buildCategoryPodium(
            title: 'Kartu Kuning Terbanyak',
            players: _topYellowCards.take(3).toList(),
            statType: 'yellow',
            emoji: '🟨',
          ),
          const SizedBox(height: 24),
        ],
        
        // Top Red Cards  
        if (_topRedCards.isNotEmpty) ...[
          _buildCategoryPodium(
            title: 'Kartu Merah Terbanyak',
            players: _topRedCards.take(3).toList(),
            statType: 'red',
            emoji: '🟥',
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryPodium({
    required String title,
    required List<dynamic> players,
    required String statType,
    required String emoji,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [Colors.grey.shade900, const Color(0xFF1F2937)]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Emoji
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Podium (2nd, 1st, 3rd positions)
          if (players.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd Place (Left, shorter)
                if (players.length > 1)
                  Expanded(
                    child: _buildModernPodiumCard(
                      players[1],
                      rank: 2,
                      statType: statType,
                      height: 180,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                  
                const SizedBox(width: 12),
                
                // 1st Place (Center, tallest)
                Expanded(
                  child: _buildModernPodiumCard(
                    players[0],
                    rank: 1,
                    statType: statType,
                    height: 220,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 3rd Place (Right, shortest)
                if (players.length > 2)
                  Expanded(
                    child: _buildModernPodiumCard(
                      players[2],
                      rank: 3,
                      statType: statType,
                      height: 180,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildModernPodiumCard(
    Map<String, dynamic> playerData, {
    required int rank,
    required String statType,
    required double height,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final player = playerData['player'] as Map<String, dynamic>;
    final statistics = playerData['statistics'] as List;
    final teamStats = statistics.isNotEmpty ? statistics[0] as Map<String, dynamic> : {};
    final team = teamStats['team'] as Map<String, dynamic>?;
    
    final playerId = player['id'] as int? ?? 0;
    final playerName = player['name'] as String? ?? 'Unknown';
    final playerPhoto = player['photo'] as String? ?? '';
    final teamName = team?['name'] as String? ?? '';
    final teamLogo = team?['logo'] as String? ?? '';
    
    // Get stat value based on type
    int statValue = 0;
    if (statType == 'goals') {
      statValue = (teamStats['goals']?['total'] ?? 0) as int;
    } else if (statType == 'assists') {
      statValue = (teamStats['goals']?['assists'] ?? 0) as int;
    } else if (statType == 'yellow') {
      statValue = (teamStats['cards']?['yellow'] ?? 0) as int;
    } else if (statType == 'red') {
      statValue = (teamStats['cards']?['red'] ?? 0) as int;
    }
    
    // Medal colors and styling
    Color medalColor;
    IconData medalIcon;
    Color cardColor;
    
    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
      medalIcon = Icons.workspace_premium;
      cardColor = isDark ? const Color(0xFF2D3748) : Colors.white;
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.workspace_premium;
      cardColor = isDark ? const Color(0xFF1A202C) : Colors.grey.shade50;
    } else {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.workspace_premium;
      cardColor = isDark ? const Color(0xFF1A202C) : Colors.grey.shade50;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(
              playerId: playerId,
              playerName: playerName,
              playerPhoto: playerPhoto,
              teamName: teamName,
              teamLogo: teamLogo,
            ),
          ),
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: rank == 1
              ? Border.all(color: medalColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.15),
              blurRadius: rank == 1 ? 12 : 8,
              offset: Offset(0, rank == 1 ? 6 : 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Medal Icon
            Icon(
              medalIcon,
              color: medalColor,
              size: rank == 1 ? 32 : 24,
            ),
            const SizedBox(height: 8),
            
            // Player Photo with border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: medalColor,
                  width: rank == 1 ? 3 : 2,
                ),
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 32 : 26,
                backgroundImage: playerPhoto.isNotEmpty
                    ? CachedNetworkImageProvider(playerPhoto)
                    : null,
                child: playerPhoto.isEmpty
                    ? Icon(Icons.person, size: rank == 1 ? 32 : 26)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            
            // Player Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                playerName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: rank == 1 ? 13 : 12,
                  fontWeight: rank == 1 ? FontWeight.bold : FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            
            // Stat Value with background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$statValue',
                style: TextStyle(
                  fontSize: rank == 1 ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Matches tab with sub-tabs for Upcoming and Finished matches
  Widget _buildMatchesTab() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Sub-tab bar for Mendatang/Selesai
        Container(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade50,
          child: TabBar(
            controller: _matchTabController,
            labelColor: theme.brightness == Brightness.dark
                ? Colors.white
                : theme.primaryColor,
            unselectedLabelColor: theme.brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            indicatorColor: theme.primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Mendatang'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
        // Sub-tab content
        Expanded(
          child: TabBarView(
            controller: _matchTabController,
            children: [
              _buildUpcomingMatches(),
              _buildFinishedMatches(),
            ],
          ),
        ),
      ],
    );
  }

  /// Build upcoming/live matches view
  Widget _buildUpcomingMatches() {
    if (_isLoadingUpcoming) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingFixtures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pertandingan mendatang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUpcomingMatches,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _upcomingFixtures.length,
        itemBuilder: (context, index) {
          final match = _upcomingFixtures[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  /// Build finished matches view
  Widget _buildFinishedMatches() {
    if (_isLoadingFinished) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_finishedFixtures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada hasil pertandingan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFinishedMatches,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _finishedFixtures.length,
        itemBuilder: (context, index) {
          final match = _finishedFixtures[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  /// Build separate group section with its own header and standings
  Widget _buildGroupSection(String groupName, List<StandingModel> groupStandings) {
    if (groupStandings.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              groupName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          
          // Standings header
          _buildStandingsHeader(),
          
          // Standings list for this group
          Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupStandings.length,
              itemBuilder: (context, index) {
                final standing = groupStandings[index];
                return _buildStandingRow(standing, groupStandings);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build single group view (for selected group or regular league)
  Widget _buildSingleGroupView(List<StandingModel> standings) {
    return Column(
      children: [
        // Standings table header
        _buildStandingsHeader(),
        // Standings list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: standings.length,
          itemBuilder: (context, index) {
            final standing = standings[index];
            return _buildStandingRow(standing, standings);
          },
        ),
      ],
    );
  }



  /// Build group selector dropdown for tournaments with multiple groups
  Widget _buildGroupSelector(List<String?> availableGroups) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: DropdownButtonHideUnderline(
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade800.withOpacity(0.8)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tune,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Grup:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButton<String?>(
                  isExpanded: true,
                value: _selectedGroup,
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  size: 16,
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                dropdownColor: theme.brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.white,
                selectedItemBuilder: (BuildContext context) {
                  return [
                    Text(
                      'Semua Grup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    ...availableGroups.map((group) => Text(
                      _getShortGroupName(group ?? 'Unknown'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    )).toList(),
                  ];
                },
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Semua Grup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  ...availableGroups.map((group) => DropdownMenuItem<String?>(
                    value: group,
                    child: Text(
                      _getShortGroupName(group ?? 'Unknown'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  )).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value;
                  });
                },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get shorter group name for display
  String _getShortGroupName(String groupName) {
    // Extract just the group letter/identifier from long names
    if (groupName.contains('Group A')) return 'Grup A';
    if (groupName.contains('Group B')) return 'Grup B';
    if (groupName.contains('Group C')) return 'Grup C';
    if (groupName.contains('Group D')) return 'Grup D';
    if (groupName.contains('Group E')) return 'Grup E';
    if (groupName.contains('Group F')) return 'Grup F';
    if (groupName.contains('Group G')) return 'Grup G';
    if (groupName.contains('Group H')) return 'Grup H';
    
    // Fallback: take last word if it's short, or abbreviate
    final parts = groupName.split(' ');
    final lastPart = parts.isNotEmpty ? parts.last : groupName;
    
    if (lastPart.length <= 6) {
      return lastPart;
    }
    
    // If still too long, abbreviate
    return groupName.length > 15 
        ? '${groupName.substring(0, 12)}...' 
        : groupName;
  }



  /// Build standings table header
  Widget _buildStandingsHeader() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(40),  // Pos - MUST match data rows
          1: FlexColumnWidth(3),    // Team - MUST match data rows  
          2: FixedColumnWidth(32),  // MP - MUST match data rows
          3: FixedColumnWidth(28),  // W - MUST match data rows
          4: FixedColumnWidth(28),  // D - MUST match data rows
          5: FixedColumnWidth(28),  // L - MUST match data rows
          6: FixedColumnWidth(38),  // GD - MUST match data rows
          7: FixedColumnWidth(38),  // Pts - MUST match data rows
        },
        children: [
          TableRow(
            children: [
              _buildHeaderCell('Pos', theme),
              _buildHeaderCell('Tim', theme, isTeamColumn: true),
              _buildHeaderCell('MP', theme),
              _buildHeaderCell('W', theme),
              _buildHeaderCell('D', theme),
              _buildHeaderCell('L', theme),
              _buildHeaderCell('GD', theme),
              _buildHeaderCell('Pts', theme, isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, ThemeData theme, {bool isTeamColumn = false, bool isBold = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTeamColumn ? 12 : 4,
        vertical: 12,
      ),
      child: Text(
        text,
        textAlign: isTeamColumn ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Build compact one-line qualification legend
  Widget _buildCompactQualificationLegend(List<StandingModel> standings) {
    final theme = Theme.of(context);
    
    // Extract unique qualification zones using hybrid detection
    final qualificationZones = <String, Color>{};
    
    for (final standing in standings) {
      final description = standing.description?.trim();
      if (description != null && description.isNotEmpty) {
        // Use the EXACT same hybrid logic to get color
        final color = _getQualificationRowColorHybrid(standing, standings, theme);
        
        if (color != null) {
          // Determine zone type based on position and description
          final lowerDesc = description.toLowerCase();
          String normalizedDesc;
          Color indicatorColor;
          
          final position = standing.rank;
          final totalTeams = standings.length;
          final isTopThird = position <= (totalTeams / 3).ceil();
          final isBottomQuarter = position > (totalTeams * 0.75);
          
          if (isBottomQuarter) {
            normalizedDesc = 'Zona Degradasi';
            indicatorColor = Colors.red.shade600;
          } else if (isTopThird) {
            if (lowerDesc.contains('europa')) {
              normalizedDesc = 'Liga Europa';
              indicatorColor = Colors.blue.shade600;
            } else if (lowerDesc.contains('conference')) {
              normalizedDesc = 'Liga Konferensi';
              indicatorColor = Colors.orange.shade600;
            } else if (lowerDesc.contains('playoff')) {
              normalizedDesc = 'Promosi';
              indicatorColor = Colors.green.shade600;
            } else {
              normalizedDesc = 'Kualifikasi';
              indicatorColor = Colors.green.shade600;
            }
          } else {
            normalizedDesc = 'Playoff';
            indicatorColor = Colors.orange.shade600;
          }
          
          // Only add unique zones
          if (!qualificationZones.containsKey(normalizedDesc)) {
            qualificationZones[normalizedDesc] = indicatorColor;
          }
        }
      }
    }
    
    if (qualificationZones.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade900.withOpacity(0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keterangan Zona:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: qualificationZones.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.value,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build match card for fixture list
  Widget _buildMatchCard(FixtureModel match) {
    final theme = Theme.of(context);
    final isLive = match.isLive;
    final isFinished = match.isFinished;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLive
              ? Colors.green.shade300
              : theme.brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
          width: isLive ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailScreen(fixture: match),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status and Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Match Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLive
                          ? Colors.green.shade100
                          : isFinished
                              ? Colors.grey.shade200
                              : theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLive) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isLive
                              ? "${match.status.elapsed}'"
                              : match.status.short,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLive
                                ? Colors.green.shade700
                                : isFinished
                                    ? Colors.grey.shade700
                                    : theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Match Date/Time
                  Text(
                    _formatMatchDateTime(match.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Teams Row
              Row(
                children: [
                  // Home Team
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: match.homeTeam.logo,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.sports_soccer,
                                size: 20,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Score or VS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (match.homeGoals != null && match.awayGoals != null)
                          Row(
                            children: [
                              Text(
                                '${match.homeGoals}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              Text(
                                '${match.awayGoals}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        // Halftime score if available
                        if (match.halftimeHome != null && match.halftimeAway != null && isFinished)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '(HT: ${match.halftimeHome}-${match.halftimeAway})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Away Team
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: match.awayTeam.logo,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.sports_soccer,
                                size: 20,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format match date/time for display
  String _formatMatchDateTime(DateTime utcDate) {
    // Convert UTC to WIB (UTC+7) for display
    final wibDate = utcDate.add(const Duration(hours: 7));
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final difference = wibDate.difference(nowWib);
    
    if (difference.inDays == 0) {
      // Today - show time with WIB
      return '${wibDate.hour.toString().padLeft(2, '0')}:${wibDate.minute.toString().padLeft(2, '0')} WIB';
    } else if (difference.inDays == 1) {
      return 'Besok';
    } else if (difference.inDays == -1) {
      return 'Kemarin';
    } else if (difference.inDays > 1 && difference.inDays <= 7) {
      return '${difference.inDays} hari lagi';
    } else if (difference.inDays < -1 && difference.inDays >= -7) {
      return '${difference.inDays.abs()} hari lalu';
    } else {
      // Show date
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${wibDate.day} ${months[wibDate.month - 1]}';
    }
  }
}
