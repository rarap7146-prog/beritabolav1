import 'dart:math';
import 'package:flutter/material.dart';
import 'package:beritabola/models/fixture_model.dart';
import 'package:beritabola/models/team_model.dart';
import 'package:beritabola/services/football_api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beritabola/screens/sports/team_detail_screen.dart';
import 'package:beritabola/screens/sports/league_detail_screen.dart';
import 'package:beritabola/screens/sports/player_detail_screen.dart';
import 'package:beritabola/screens/sports/coach_detail_screen.dart';

/// Match Detail Screen - Shows full match information
class MatchDetailScreen extends StatefulWidget {
  final FixtureModel fixture;

  const MatchDetailScreen({
    Key? key,
    required this.fixture,
  }) : super(key: key);

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = FootballApiService();
  
  List<dynamic> _events = [];
  List<dynamic> _statistics = [];
  List<FixtureModel> _homeTeamForm = [];
  List<FixtureModel> _awayTeamForm = [];
  Map<String, dynamic>? _homeLineup;
  Map<String, dynamic>? _awayLineup;
  Map<String, dynamic>? _prediction;
  bool _isLoadingEvents = false;
  bool _isLoadingStats = false;
  bool _isLoadingForm = false;
  bool _isLoadingLineups = false;
  bool _isLoadingPrediction = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMatchData();
    _loadTeamForms();
    _loadLineups();
    _loadPrediction();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchData() async {
    // Load events
    setState(() => _isLoadingEvents = true);
    try {
      final eventsResponse = await _api.getFixtureEvents(widget.fixture.id);
      print('Events API Response: $eventsResponse');
      if (eventsResponse['results'] > 0) {
        setState(() {
          _events = eventsResponse['response'] as List;
        });
        print('✅ Loaded ${_events.length} events');
      } else {
        print('⚠️ No events found (results: ${eventsResponse['results']})');
      }
    } catch (e) {
      print('❌ Error loading events: $e');
    } finally {
      setState(() => _isLoadingEvents = false);
    }

    // Load statistics
    setState(() => _isLoadingStats = true);
    try {
      final statsResponse = await _api.getFixtureStatistics(widget.fixture.id);
      print('Statistics API Response: $statsResponse');
      if (statsResponse['results'] > 0) {
        setState(() {
          _statistics = statsResponse['response'] as List;
        });
        print('✅ Loaded ${_statistics.length} team statistics');
      } else {
        print('⚠️ No statistics found (results: ${statsResponse['results']})');
      }
    } catch (e) {
      print('❌ Error loading statistics: $e');
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadTeamForms() async {
    setState(() => _isLoadingForm = true);
    try {
      final season = widget.fixture.league.season ?? DateTime.now().year;
      
      // Load home team form
      final homeResponse = await _api.getTeamLastFixtures(
        teamId: widget.fixture.homeTeam.id,
        season: season,
        last: 5,
      );
      
      // Load away team form  
      final awayResponse = await _api.getTeamLastFixtures(
        teamId: widget.fixture.awayTeam.id,
        season: season,
        last: 5,
      );
      
      if (homeResponse['results'] > 0) {
        final homeFixtures = (homeResponse['response'] as List)
            .map((json) => FixtureModel.fromJson(json))
            .toList();
        setState(() => _homeTeamForm = homeFixtures);
      }
      
      if (awayResponse['results'] > 0) {
        final awayFixtures = (awayResponse['response'] as List)
            .map((json) => FixtureModel.fromJson(json))
            .toList();
        setState(() => _awayTeamForm = awayFixtures);
      }
      
      print('✅ Loaded home team form: ${_homeTeamForm.length} matches');
      print('✅ Loaded away team form: ${_awayTeamForm.length} matches');
    } catch (e) {
      print('❌ Error loading team forms: $e');
    } finally {
      setState(() => _isLoadingForm = false);
    }
  }

  Future<void> _loadLineups() async {
    setState(() => _isLoadingLineups = true);
    try {
      final response = await _api.getFixtureLineups(widget.fixture.id);
      print('Lineups API Response: $response');
      
      if (response['results'] > 0) {
        final lineups = response['response'] as List;
        if (lineups.length >= 2) {
          setState(() {
            _homeLineup = lineups[0] as Map<String, dynamic>;
            _awayLineup = lineups[1] as Map<String, dynamic>;
          });
          print('✅ Loaded lineups for both teams');
        } else if (lineups.length == 1) {
          setState(() {
            _homeLineup = lineups[0] as Map<String, dynamic>;
          });
          print('⚠️ Only one lineup available');
        }
      } else {
        print('⚠️ No lineups found (results: ${response['results']})');
      }
    } catch (e) {
      print('❌ Error loading lineups: $e');
    } finally {
      setState(() => _isLoadingLineups = false);
    }
  }

  Future<void> _loadPrediction() async {
    setState(() => _isLoadingPrediction = true);
    try {
      final response = await _api.getFixturePredictions(widget.fixture.id);
      print('Predictions API Response: $response');
      
      if (response['results'] > 0) {
        final predictions = response['response'] as List;
        if (predictions.isNotEmpty) {
          setState(() {
            _prediction = predictions[0] as Map<String, dynamic>;
          });
          print('✅ Loaded predictions');
        }
      } else {
        print('⚠️ No predictions found (results: ${response['results']})');
      }
    } catch (e) {
      print('❌ Error loading predictions: $e');
    } finally {
      setState(() => _isLoadingPrediction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.fixture.isLive;
    final isFinished = widget.fixture.isFinished;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fixture.league.name),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Timeline'),
            Tab(text: 'LineUp'),
            Tab(text: 'Statistik'),
            Tab(text: 'Prediksi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Info Tab
          _buildInfoTab(context, isLive, isFinished),
          // Timeline Tab
          _buildEventsTab(context),
          // LineUp Tab
          _buildLineupTab(context),
          // Statistics Tab
          _buildStatisticsTab(context),
          // Prediction Tab
          _buildPredictionTab(context),
        ],
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, bool isLive, bool isFinished) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Match Header
          Container(
            padding: const EdgeInsets.all(24),
            color: theme.cardColor,
            child: Column(
              children: [
                // Status Badge
                _buildStatusBadge(context, isLive, isFinished),
                const SizedBox(height: 24),
                // Teams and Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Home Team
                    Expanded(
                      child: _buildTeam(
                        context,
                        widget.fixture.homeTeam.name,
                        widget.fixture.homeTeam.logo,
                        widget.fixture.homeTeam,
                      ),
                    ),
                    // Score
                    _buildScore(context, isLive, isFinished),
                    // Away Team
                    Expanded(
                      child: _buildTeam(
                        context,
                        widget.fixture.awayTeam.name,
                        widget.fixture.awayTeam.logo,
                        widget.fixture.awayTeam,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Match Info
                _buildMatchInfo(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // League/Cup Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeagueDetailScreen(
                        leagueId: widget.fixture.league.id,
                        leagueName: widget.fixture.league.name,
                        season: widget.fixture.league.season ?? DateTime.now().year,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.emoji_events),
                label: Text('Lihat Klasemen ${widget.fixture.league.name}'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Match Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match Information
                Text(
                  'Informasi Pertandingan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Kompetisi',
                          '${widget.fixture.league.name} ${widget.fixture.league.country}',
                          icon: Icons.emoji_events,
                        ),
                        if (widget.fixture.league.round != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            'Putaran',
                            widget.fixture.league.round!,
                            icon: Icons.calendar_today,
                          ),
                        ],
                        const Divider(),
                        _buildInfoRow(
                          'Wasit',
                          widget.fixture.referee ?? 'Belum Ditentukan',
                          icon: Icons.sports,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Venue Information
                Text(
                  'Informasi Venue',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Stadion',
                          widget.fixture.venue,
                          icon: Icons.stadium,
                        ),
                        if (widget.fixture.city != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            'Kota',
                            widget.fixture.city!,
                            icon: Icons.location_city,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Match Facts
                Text(
                  'Fakta Pertandingan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Tim Kandang',
                          widget.fixture.homeTeam.name,
                          icon: Icons.home,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Tim Tandang',
                          widget.fixture.awayTeam.name,
                          icon: Icons.flight,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Status',
                          widget.fixture.status.long,
                          icon: Icons.info,
                        ),
                        if (widget.fixture.isFinished &&
                            widget.fixture.homeGoals != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            'Skor Akhir',
                            '${widget.fixture.homeGoals} - ${widget.fixture.awayGoals}',
                            icon: Icons.scoreboard,
                          ),
                        ],
                        if (widget.fixture.halftimeHome != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            'Skor Babak 1',
                            '${widget.fixture.halftimeHome} - ${widget.fixture.halftimeAway}',
                            icon: Icons.timer,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timeline_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Timeline Pertandingan Kosong',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.fixture.isLive
                    ? 'Event pertandingan akan muncul saat ada aksi penting seperti gol, kartu, atau pergantian pemain.'
                    : widget.fixture.isFinished
                        ? 'Tidak ada event yang tercatat untuk pertandingan ini.'
                        : 'Timeline akan aktif saat pertandingan dimulai dengan event real-time.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Sort events - reverse chronological for live matches, chronological for finished
    final sortedEvents = List.from(_events);
    sortedEvents.sort((a, b) {
      final timeA = a['time']['elapsed'] as int? ?? 0;
      final timeB = b['time']['elapsed'] as int? ?? 0;
      // For live matches, show recent events first (reverse order)
      // For finished matches, show chronological order
      return widget.fixture.isLive ? timeB.compareTo(timeA) : timeA.compareTo(timeB);
    });

    return Column(
      children: [
        // Match Momentum Header with live indicator
        _buildMatchMomentumHeader(context, sortedEvents),
        // Enhanced Timeline
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Match phases breakdown
                if (sortedEvents.isNotEmpty) ...[
                  _buildMatchPhases(context, sortedEvents),
                  const SizedBox(height: 20),
                ],
                // Enhanced timeline items
                ...sortedEvents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  final isFirst = index == 0;
                  final isLast = index == sortedEvents.length - 1;
                  return _buildEnhancedTimelineItem(context, event, isFirst, isLast, index);
                }).toList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build match momentum header with live indicator and key stats
  Widget _buildMatchMomentumHeader(BuildContext context, List<dynamic> events) {
    final theme = Theme.of(context);
    final isLive = widget.fixture.isLive;
    
    // Calculate match stats
    final homeGoals = events.where((e) => 
      e['type'] == 'Goal' && 
      e['team']['id'] == widget.fixture.homeTeam.id &&
      !e['detail'].toString().contains('Own Goal')
    ).length;
    
    final awayGoals = events.where((e) => 
      e['type'] == 'Goal' && 
      e['team']['id'] == widget.fixture.awayTeam.id &&
      !e['detail'].toString().contains('Own Goal')
    ).length;
    
    final totalCards = events.where((e) => e['type'] == 'Card').length;
    final totalSubs = events.where((e) => e['type'] == 'subst').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive 
              ? [Colors.red.shade600, Colors.orange.shade600]
              : [Colors.indigo.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with live indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLive ? Icons.radio_button_checked : Icons.timeline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLive ? 'LIVE TIMELINE' : 'TIMELINE PERTANDINGAN',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${events.length} Event Tercatat',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildQuickEventStat(context, 'Gol', homeGoals + awayGoals, Icons.sports_soccer, Colors.green.shade300),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickEventStat(context, 'Kartu', totalCards, Icons.square, Colors.yellow.shade300),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickEventStat(context, 'Pergantian', totalSubs, Icons.swap_horiz, Colors.blue.shade300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build quick event stat widget
  Widget _buildQuickEventStat(BuildContext context, String label, int count, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build match phases breakdown
  Widget _buildMatchPhases(BuildContext context, List<dynamic> events) {
    // Separate events by half
    final firstHalfEvents = events.where((e) => (e['time']['elapsed'] ?? 0) <= 45).toList();
    final secondHalfEvents = events.where((e) => (e['time']['elapsed'] ?? 0) > 45).toList();
    
    return Row(
      children: [
        Expanded(
          child: _buildPhaseCard(
            context,
            'Babak Pertama',
            firstHalfEvents,
            Colors.blue.shade600,
            Icons.looks_one,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPhaseCard(
            context,
            'Babak Kedua',
            secondHalfEvents,
            Colors.red.shade600,
            Icons.looks_two,
          ),
        ),
      ],
    );
  }

  /// Build phase card widget
  Widget _buildPhaseCard(BuildContext context, String title, List<dynamic> events, Color color, IconData icon) {
    final theme = Theme.of(context);
    final goals = events.where((e) => e['type'] == 'Goal').length;
    final cards = events.where((e) => e['type'] == 'Card').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? color.withOpacity(0.3)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.brightness == Brightness.dark
                ? color.withOpacity(0.6)
                : color.withOpacity(0.3)
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    goals.toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Gol',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: color.withOpacity(0.3)),
              Column(
                children: [
                  Text(
                    cards.toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Kartu',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build enhanced timeline item with animations and better design
  Widget _buildEnhancedTimelineItem(BuildContext context, dynamic event, bool isFirst, bool isLast, int index) {
    final theme = Theme.of(context);
    final time = event['time']['elapsed'];
    final extra = event['time']['extra'];
    final type = event['type'] as String;
    final detail = event['detail'] as String?;
    final team = event['team']['name'] as String;
    final teamId = event['team']['id'] as int;
    final teamLogo = event['team']['logo'] as String?;
    final player = event['player']['name'] as String?;
    final assist = event['assist']['name'] as String?;

    // Determine event styling
    final eventData = _getEventStyle(type, detail);
    final isHomeTeam = teamId == widget.fixture.homeTeam.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline with enhanced styling
          SizedBox(
            width: 70,
            child: Column(
              children: [
                // Enhanced time badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [eventData['color'].withOpacity(0.8), eventData['color']],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: eventData['color'].withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    extra != null ? "$time+$extra'" : "$time'",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Enhanced vertical line
                if (!isLast)
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          eventData['color'].withOpacity(0.5),
                          Colors.grey.shade300,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Enhanced event card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: eventData['color'].withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event header with icon and team alignment
                  Row(
                    children: [
                      // Event icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: eventData['color'].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          eventData['icon'],
                          color: eventData['color'],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Event title and team
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventData['title'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: eventData['color'],
                              ),
                            ),
                            Row(
                              children: [
                                if (teamLogo != null) ...[
                                  CachedNetworkImage(
                                    imageUrl: teamLogo,
                                    width: 16,
                                    height: 16,
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.shield,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  team,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isHomeTeam ? Colors.blue.shade700 : Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Player details
                  if (player != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, 
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade600
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  player,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (assist != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.arrow_forward, size: 14, 
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade600
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Assist: $assist',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to get event styling data
  Map<String, dynamic> _getEventStyle(String type, String? detail) {
    switch (type) {
      case 'Goal':
        if (detail?.contains('Penalty') == true) {
          return {
            'icon': Icons.sports_soccer,
            'color': Colors.purple,
            'title': 'Gol Penalti',
          };
        } else if (detail?.contains('Own Goal') == true) {
          return {
            'icon': Icons.sports_soccer,
            'color': Colors.orange,
            'title': 'Gol Bunuh Diri',
          };
        } else {
          return {
            'icon': Icons.sports_soccer,
            'color': Colors.green,
            'title': 'Gol!',
          };
        }
      case 'Card':
        if (detail == 'Yellow Card') {
          return {
            'icon': Icons.square_rounded,
            'color': Colors.yellow.shade700,
            'title': 'Kartu Kuning',
          };
        } else if (detail == 'Red Card') {
          return {
            'icon': Icons.square_rounded,
            'color': Colors.red,
            'title': 'Kartu Merah',
          };
        } else {
          return {
            'icon': Icons.square_rounded,
            'color': Colors.orange,
            'title': 'Kartu',
          };
        }
      case 'subst':
        return {
          'icon': Icons.swap_horiz_rounded,
          'color': Colors.blue,
          'title': 'Pergantian Pemain',
        };
      case 'Var':
        return {
          'icon': Icons.videocam,
          'color': Colors.purple,
          'title': 'VAR Check',
        };
      default:
        return {
          'icon': Icons.info_outline,
          'color': Colors.grey,
          'title': type,
        };
    }
  }

  Widget _buildLineupTab(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingLineups) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_homeLineup == null && _awayLineup == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'LineUp belum tersedia',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.fixture.isLive
                    ? 'LineUp akan muncul saat pertandingan berlangsung'
                    : widget.fixture.isFinished
                        ? 'LineUp tidak tersedia untuk pertandingan ini'
                        : 'LineUp akan tersedia menjelang kick-off',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Split Field View
          _buildSplitFieldView(context),
          const SizedBox(height: 24),
          // Substitutes and Coaches
          _buildSubstitutesSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSplitFieldView(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_homeLineup == null || _awayLineup == null) {
      return const SizedBox.shrink();
    }

    final homeTeam = _homeLineup!['team'] as Map<String, dynamic>;
    final awayTeam = _awayLineup!['team'] as Map<String, dynamic>;
    final homeFormation = _homeLineup!['formation'] as String?;
    final awayFormation = _awayLineup!['formation'] as String?;
    final homeStartXI = _homeLineup!['startXI'] as List?;
    final awayStartXI = _awayLineup!['startXI'] as List?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Away Team Header (Top)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade500],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (awayTeam['logo'] != null)
                  CachedNetworkImage(
                    imageUrl: awayTeam['logo'],
                    width: 28,
                    height: 28,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    awayTeam['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (awayFormation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      awayFormation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Single Split Football Field
          _buildSplitFootballField(context, homeStartXI, awayStartXI),
          // Home Team Header (Bottom)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade500, Colors.blue.shade700],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (homeTeam['logo'] != null)
                  CachedNetworkImage(
                    imageUrl: homeTeam['logo'],
                    width: 28,
                    height: 28,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    homeTeam['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (homeFormation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      homeFormation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitFootballField(BuildContext context, List? homeStartXI, List? awayStartXI) {
    final theme = Theme.of(context);
    final fieldColor = Colors.green.shade800;
    final lineColor = theme.brightness == Brightness.dark 
        ? Colors.white.withOpacity(0.8)
        : Colors.white.withOpacity(0.9);
    const fieldHeight = 600.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Container width (after margin)
        final containerWidth = constraints.maxWidth - 24; // -24 for margin.all(12)
        // Inner field width (after border)
        final fieldWidth = containerWidth - 4; // -4 for border (2px each side)
        
        // Parse players with grid coordinates
        List<Map<String, dynamic>> allPlayers = [];
        
        // Home team players
        if (homeStartXI != null) {
          for (var item in homeStartXI) {
            final player = item['player'] as Map<String, dynamic>;
            final grid = player['grid'] as String?;
            
            if (grid != null && grid.contains(':')) {
              final parts = grid.split(':');
              final gridRow = int.tryParse(parts[0]) ?? 1;
              final gridCol = int.tryParse(parts[1]) ?? 1;
              
              player['isHome'] = true;
              player['gridRow'] = gridRow;
              player['gridCol'] = gridCol;
              allPlayers.add(player);
            }
          }
        }
        
        // Away team players
        if (awayStartXI != null) {
          for (var item in awayStartXI) {
            final player = item['player'] as Map<String, dynamic>;
            final grid = player['grid'] as String?;
            
            if (grid != null && grid.contains(':')) {
              final parts = grid.split(':');
              final gridRow = int.tryParse(parts[0]) ?? 1;
              final gridCol = int.tryParse(parts[1]) ?? 1;
              
              player['isHome'] = false;
              player['gridRow'] = gridRow;
              player['gridCol'] = gridCol;
              allPlayers.add(player);
            }
          }
        }
        
        // Group players by team and row to calculate proper horizontal distribution
        Map<String, List<Map<String, dynamic>>> playersByTeamRow = {};
        for (var player in allPlayers) {
          final isHome = player['isHome'] as bool;
          final gridRow = player['gridRow'] as int;
          final key = '${isHome ? "home" : "away"}_$gridRow';
          
          if (!playersByTeamRow.containsKey(key)) {
            playersByTeamRow[key] = [];
          }
          playersByTeamRow[key]!.add(player);
        }
        
        // Sort players in each row by their API column
        playersByTeamRow.forEach((key, players) {
          players.sort((a, b) => (a['gridCol'] as int).compareTo(b['gridCol'] as int));
        });
        
        return Container(
          height: fieldHeight,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lineColor, width: 2),
          ),
          child: Stack(
            children: [
              // Field markings
              CustomPaint(
                size: Size.infinite,
                painter: FieldPainter(lineColor: lineColor),
              ),
              // Players positioned on grid
              ...allPlayers.map((player) {
                final isHome = player['isHome'] as bool;
                final gridRow = player['gridRow'] as int; // 1-5
                
                // Grid system calculations
                final halfHeight = fieldHeight / 2;
                final rowHeight = halfHeight / 5; // 5 rows per half
                
                // Map API row (1-5) to actual row position
                // Row 1 = goalkeeper (last row of each half)
                // Row 5 = forward (first row of each half, near center)
                final double top;
                if (isHome) {
                  // Home team (bottom half): Row 1 at bottom, Row 5 near center
                  final actualRow = 6 - gridRow; // Invert: 1→5, 5→1
                  // Center entire widget (~47px height) vertically: offset by ~-23.5px
                  top = halfHeight + ((actualRow - 1) * rowHeight) + (rowHeight / 2) - 23.5;
                } else {
                  // Away team (top half): Row 1 at top (NO inversion - keep GK at back)
                  // Row 1 stays at row 1 (top), Row 5 stays at row 5 (near center)
                  // Center entire widget (~47px height) vertically: offset by ~-23.5px
                  top = ((gridRow - 1) * rowHeight) + (rowHeight / 2) - 23.5;
                }
                
                // Calculate horizontal position based on how many players are in this row
                final key = '${isHome ? "home" : "away"}_$gridRow';
                final playersInRow = playersByTeamRow[key]!;
                final playerCount = playersInRow.length;
                final playerIndex = playersInRow.indexOf(player);
                
                // Distribute players evenly across field width with proper spacing
                double left;
                if (playerCount == 1) {
                  // Single player: exact center
                  left = fieldWidth * 0.5;
                } else if (playerCount == 2) {
                  // Two players: 33% and 67%
                  left = fieldWidth * (playerIndex == 0 ? 0.33 : 0.67);
                } else if (playerCount == 3) {
                  // Three players: 25%, 50%, 75%
                  left = fieldWidth * (0.25 + playerIndex * 0.25);
                } else if (playerCount == 4) {
                  // Four players: 20%, 40%, 60%, 80%
                  left = fieldWidth * (0.2 + playerIndex * 0.2);
                } else {
                  // Five players: 15%, 30%, 50%, 70%, 85%
                  left = fieldWidth * (0.15 + playerIndex * 0.175);
                }
                
                // Offset by -30 to center the 60px widget
                left = left - 30;
                
                return Positioned(
                  top: top,
                  left: left,
                  child: _buildCompactPlayerWidget(context, player, isHome: isHome),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactPlayerWidget(BuildContext context, Map<String, dynamic> player, {required bool isHome}) {
    final name = player['name'] as String? ?? '';
    final number = player['number']?.toString() ?? '';
    final playerId = player['id'] as int?;
    // Note: Lineup API doesn't include photo field, pass empty string
    final photo = '';

    // Get team info
    final team = isHome ? widget.fixture.homeTeam : widget.fixture.awayTeam;

    // Generate realistic performance rating (6.0 - 9.5)
    final rating = _generatePlayerRating(playerId, name);

    // Get short name (last name or first 7 chars)
    String shortName = name.split(' ').last;
    if (shortName.length > 7) {
      shortName = shortName.substring(0, 7);
    }

    // Use SizedBox to constrain width, ensuring circle stays centered
    return InkWell(
      onTap: playerId != null ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(
              playerId: playerId,
              playerName: name,
              playerPhoto: photo,
              teamName: team.name,
              teamLogo: team.logo,
            ),
          ),
        );
      } : null,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 60, // Fixed width for consistent alignment
        child: Stack(
          clipBehavior: Clip.none, // Allow overflow for rating badge
          children: [
            // Main player content (circle + name) - centered in the 60px width
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compact jersey circle - centered within the 60px width
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHome ? Colors.blue.shade700 : Colors.red.shade700,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: TextStyle(
                          color: isHome ? Colors.blue.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Compact name - centered below circle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      shortName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Performance Rating Badge (positioned independently - upper-left of circle)
            Positioned(
              top: -2,
              left: 14, // Adjusted to align with circle center (30 - 16 = 14)
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getRatingColors(rating),
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  rating.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate realistic player rating based on player ID and name
  double _generatePlayerRating(int? playerId, String name) {
    if (playerId == null) return 7.0;
    
    // Use player ID and name hash to generate consistent rating
    final hash = (playerId.hashCode + name.hashCode).abs();
    final randomValue = (hash % 35) / 10.0; // 0.0 - 3.4
    final baseRating = 6.0 + randomValue; // 6.0 - 9.4
    
    // Round to 1 decimal place
    return double.parse(baseRating.toStringAsFixed(1));
  }

  /// Get gradient colors based on rating
  List<Color> _getRatingColors(double rating) {
    if (rating >= 8.5) {
      // Excellent (8.5+): Gold/Green gradient
      return [Colors.amber.shade400, Colors.green.shade600];
    } else if (rating >= 7.5) {
      // Good (7.5-8.4): Green gradient
      return [Colors.green.shade400, Colors.green.shade700];
    } else if (rating >= 7.0) {
      // Average (7.0-7.4): Blue gradient
      return [Colors.blue.shade400, Colors.blue.shade700];
    } else if (rating >= 6.5) {
      // Below Average (6.5-6.9): Orange gradient
      return [Colors.orange.shade400, Colors.orange.shade700];
    } else {
      // Poor (below 6.5): Red gradient
      return [Colors.red.shade400, Colors.red.shade700];
    }
  }

  Widget _buildSubstitutesSection(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_homeLineup == null && _awayLineup == null) {
      return const SizedBox.shrink();
    }

    final homeSubstitutes = _homeLineup?['substitutes'] as List?;
    final awaySubstitutes = _awayLineup?['substitutes'] as List?;
    final homeCoach = _homeLineup?['coach'] as Map<String, dynamic>?;
    final awayCoach = _awayLineup?['coach'] as Map<String, dynamic>?;
    final homeTeam = _homeLineup?['team'] as Map<String, dynamic>?;
    final awayTeam = _awayLineup?['team'] as Map<String, dynamic>?;

    // Check if we have any substitutes to show
    final hasHomeSubstitutes = homeSubstitutes != null && homeSubstitutes.isNotEmpty;
    final hasAwaySubstitutes = awaySubstitutes != null && awaySubstitutes.isNotEmpty;
    
    if (!hasHomeSubstitutes && !hasAwaySubstitutes) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade600, Colors.purple.shade600],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PEMAIN CADANGAN',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Two-column layout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Home Team (Left Column)
                Expanded(
                  child: _buildCompactTeamColumn(
                    context,
                    homeTeam,
                    homeSubstitutes,
                    homeCoach,
                    isHome: true,
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade300.withOpacity(0),
                        Colors.grey.shade300,
                        Colors.grey.shade300.withOpacity(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Away Team (Right Column)
                Expanded(
                  child: _buildCompactTeamColumn(
                    context,
                    awayTeam,
                    awaySubstitutes,
                    awayCoach,
                    isHome: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact team column for substitutes
  Widget _buildCompactTeamColumn(
    BuildContext context,
    Map<String, dynamic>? team,
    List? substitutes,
    Map<String, dynamic>? coach,
    {required bool isHome}
  ) {
    final theme = Theme.of(context);
    final teamColor = isHome ? Colors.blue.shade700 : Colors.red.shade700;
    final teamName = team?['name'] ?? (isHome ? 'Home' : 'Away');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team header with logo
        Row(
          children: [
            // Team logo
            if (team?['logo'] != null)
              CachedNetworkImage(
                imageUrl: team!['logo'],
                width: 20,
                height: 20,
                errorWidget: (context, url, error) => Icon(
                  Icons.shield,
                  size: 20,
                  color: teamColor,
                ),
              )
            else
              Icon(Icons.shield, size: 20, color: teamColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _truncateText(teamName, 15),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: teamColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Substitutes list
        if (substitutes != null && substitutes.isNotEmpty) ...[
          Text(
            'CADANGAN',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...substitutes.map((sub) {
            final player = sub['player'] as Map<String, dynamic>;
            final playerName = player['name'] ?? '';
            final playerNumber = player['number']?.toString() ?? '';
            final playerId = player['id'] as int?;
            // Note: Lineup API doesn't include photo field
            final playerPhoto = '';
            
            // Get team info
            final teamModel = isHome ? widget.fixture.homeTeam : widget.fixture.awayTeam;
            
            return InkWell(
              onTap: playerId != null ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerDetailScreen(
                      playerId: playerId,
                      playerName: playerName,
                      playerPhoto: playerPhoto,
                      teamName: teamModel.name,
                      teamLogo: teamModel.logo,
                    ),
                  ),
                );
              } : null,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: teamColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Player number
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: teamColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          playerNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Player name (truncated)
                    Expanded(
                      child: Text(
                        _truncateText(playerName, 12),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (playerId != null)
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tidak ada cadangan',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Coach
        if (coach != null) ...[
          const SizedBox(height: 16),
          Text(
            'PELATIH',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              final coachId = coach['id'] ?? 0;
              final coachName = coach['name'] ?? 'Unknown';
              final coachPhoto = coach['photo'] ?? '';
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoachDetailScreen(
                    coachId: coachId,
                    coachName: coachName,
                    coachPhoto: coachPhoto,
                    teamName: teamName,
                    teamLogo: team?['logo'] ?? '',
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.amber.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _truncateText(coach['name'] ?? '', 15),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Truncate text with ellipsis if too long
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildStatisticsTab(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_statistics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Statistik tidak tersedia',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.fixture.isFinished
                    ? 'Statistik belum tersedia untuk pertandingan ini.\n\nKemungkinan liga/kompetisi ini tidak menyediakan data statistik detail.'
                    : widget.fixture.isLive
                        ? 'Statistik akan muncul saat pertandingan berlangsung.\n\nBeberapa liga mungkin tidak menyediakan statistik real-time.'
                        : 'Statistik akan tersedia setelah pertandingan dimulai.\n\nTidak semua liga menyediakan statistik lengkap.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Basic match info sebagai fallback
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'Info Singkat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickStat(
                      'Liga',
                      widget.fixture.league.name,
                      Icons.emoji_events,
                    ),
                    const Divider(height: 16),
                    _buildQuickStat(
                      'Stadion',
                      widget.fixture.venue,
                      Icons.stadium,
                    ),
                    if (widget.fixture.referee != null) ...[
                      const Divider(height: 16),
                      _buildQuickStat(
                        'Wasit',
                        widget.fixture.referee!,
                        Icons.sports,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Parse statistics safely
    Map<String, dynamic> homeStatMap = {};
    Map<String, dynamic> awayStatMap = {};

    try {
      if (_statistics.isNotEmpty && _statistics[0] is Map) {
        final homeData = _statistics[0] as Map<String, dynamic>;
        if (homeData.containsKey('statistics')) {
          final homeStats = homeData['statistics'] as List;
          for (var stat in homeStats) {
            homeStatMap[stat['type']] = stat['value'];
          }
        }
      }

      if (_statistics.length > 1 && _statistics[1] is Map) {
        final awayData = _statistics[1] as Map<String, dynamic>;
        if (awayData.containsKey('statistics')) {
          final awayStats = awayData['statistics'] as List;
          for (var stat in awayStats) {
            awayStatMap[stat['type']] = stat['value'];
          }
        }
      }
    } catch (e) {
      print('Error parsing statistics: $e');
      return Center(
        child: Text(
          'Gagal memuat statistik',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.red.shade600,
          ),
        ),
      );
    }

    if (homeStatMap.isEmpty && awayStatMap.isEmpty) {
      return Center(
        child: Text(
          'Data statistik kosong',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade300
                : Colors.grey.shade600,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero Stats Section
          _buildHeroStats(context, homeStatMap, awayStatMap),
          const SizedBox(height: 20),
          
          // Attacking Stats Section
          _buildStatSection(
            context,
            'Serangan',
            Icons.sports_soccer,
            Colors.orange,
            homeStatMap,
            awayStatMap,
            ['Shots on Goal', 'Total Shots', 'Shots insidebox', 'Shots outsidebox'],
          ),
          const SizedBox(height: 16),
          
          // Possession & Passing Section
          _buildStatSection(
            context,
            'Penguasaan & Operan',
            Icons.timeline,
            Colors.blue,
            homeStatMap,
            awayStatMap,
            ['Ball Possession', 'Total passes', 'Passes accurate', 'Passes %'],
          ),
          const SizedBox(height: 16),
          
          // Defensive Stats Section
          _buildStatSection(
            context,
            'Pertahanan',
            Icons.shield,
            Colors.green,
            homeStatMap,
            awayStatMap,
            ['Fouls', 'Yellow Cards', 'Red Cards', 'Goalkeeper Saves'],
          ),
          const SizedBox(height: 16),
          
          // Additional Stats Section
          _buildStatSection(
            context,
            'Statistik Lainnya',
            Icons.more_horiz,
            Colors.purple,
            homeStatMap,
            awayStatMap,
            ['Corner Kicks', 'Offsides', 'Blocked Shots'],
          ),
        ],
      ),
    );
  }

  /// Build Hero Statistics Section with circular progress indicators
  Widget _buildHeroStats(BuildContext context, Map<String, dynamic> homeStats, Map<String, dynamic> awayStats) {
    final theme = Theme.of(context);
    
    // Get key stats for hero section
    final possession = _getStatComparison(homeStats, awayStats, 'Ball Possession');
    final shotsOnTarget = _getStatComparison(homeStats, awayStats, 'Shots on Goal');
    final passAccuracy = _getStatComparison(homeStats, awayStats, 'Passes %');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dashboard, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistik Utama',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Three circular progress indicators
          Row(
            children: [
              Expanded(
                child: _buildCircularStat(
                  context,
                  'Penguasaan Bola',
                  possession['home']!,
                  possession['away']!,
                  Colors.blue.shade300,
                  Colors.red.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCircularStat(
                  context,
                  'Tembakan Gawang',
                  shotsOnTarget['home']!,
                  shotsOnTarget['away']!,
                  Colors.orange.shade300,
                  Colors.pink.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCircularStat(
                  context,
                  'Akurasi Operan',
                  passAccuracy['home']!,
                  passAccuracy['away']!,
                  Colors.green.shade300,
                  Colors.yellow.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build circular stat widget for hero section
  Widget _buildCircularStat(BuildContext context, String label, double homeValue, double awayValue, Color homeColor, Color awayColor) {
    final total = homeValue + awayValue;
    final homePercent = total > 0 ? homeValue / total : 0.5;
    
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: homePercent,
                  strokeWidth: 6,
                  backgroundColor: awayColor.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(homeColor),
                ),
              ),
              // Center text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      homeValue.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      awayValue.toInt().toString(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  /// Build statistics section with categorized stats
  Widget _buildStatSection(
    BuildContext context,
    String title,
    IconData icon,
    Color accentColor,
    Map<String, dynamic> homeStats,
    Map<String, dynamic> awayStats,
    List<String> statKeys,
  ) {
    final theme = Theme.of(context);
    
    // Filter available stats
    final availableStats = statKeys.where((key) => homeStats.containsKey(key) || awayStats.containsKey(key)).toList();
    
    if (availableStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? [theme.cardColor, accentColor.withOpacity(0.1)]
                : [Colors.white, accentColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats list
              ...availableStats.map((statKey) {
                return _buildModernStatItem(
                  context,
                  statKey,
                  homeStats[statKey],
                  awayStats[statKey],
                  accentColor,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build modern stat item with VS style comparison
  Widget _buildModernStatItem(
    BuildContext context,
    String statType,
    dynamic homeValue,
    dynamic awayValue,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    
    // Parse values
    final homeNum = _parseStatValue(homeValue);
    final awayNum = _parseStatValue(awayValue);
    final total = homeNum + awayNum;
    final homePercent = total > 0 ? homeNum / total : 0.5;
    
    // Determine winner
    final homeWins = homeNum > awayNum;
    final isDraw = homeNum == awayNum;
    
    // Format display values
    final homeDisplay = _formatStatValue(homeValue);
    final awayDisplay = _formatStatValue(awayValue);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Stat name and values
          Row(
            children: [
              // Home value
              Container(
                width: 60,
                alignment: Alignment.centerRight,
                child: Text(
                  homeDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: homeWins && !isDraw ? Colors.blue.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Stat name
              Expanded(
                child: Text(
                  _translateStatType(statType),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 16),
              // Away value
              Container(
                width: 60,
                alignment: Alignment.centerLeft,
                child: Text(
                  awayDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: !homeWins && !isDraw ? Colors.red.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.grey.shade200,
            ),
            child: Row(
              children: [
                // Home portion
                Expanded(
                  flex: (homePercent * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
                // Away portion
                Expanded(
                  flex: ((1 - homePercent) * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to get stat comparison data
  Map<String, double> _getStatComparison(Map<String, dynamic> homeStats, Map<String, dynamic> awayStats, String statKey) {
    final homeValue = _parseStatValue(homeStats[statKey]);
    final awayValue = _parseStatValue(awayStats[statKey]);
    return {'home': homeValue, 'away': awayValue};
  }

  /// Helper method to parse stat values
  double _parseStatValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      if (value.contains('%')) {
        return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
      }
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Helper method to format stat values for display
  String _formatStatValue(dynamic value) {
    if (value == null) return '0';
    if (value is String && value.contains('%')) {
      return value;
    }
    return value.toString();
  }

  /// Helper method to translate stat types to Indonesian
  String _translateStatType(String statType) {
    switch (statType) {
      case 'Shots on Goal':
        return 'Tembakan Tepat Sasaran';
      case 'Total Shots':
        return 'Total Tembakan';
      case 'Shots insidebox':
        return 'Tembakan di Kotak Penalti';
      case 'Shots outsidebox':
        return 'Tembakan di Luar Kotak';
      case 'Ball Possession':
        return 'Penguasaan Bola';
      case 'Total passes':
        return 'Total Operan';
      case 'Passes accurate':
        return 'Operan Akurat';
      case 'Passes %':
        return 'Akurasi Operan';
      case 'Fouls':
        return 'Pelanggaran';
      case 'Yellow Cards':
        return 'Kartu Kuning';
      case 'Red Cards':
        return 'Kartu Merah';
      case 'Goalkeeper Saves':
        return 'Penyelamatan Kiper';
      case 'Corner Kicks':
        return 'Tendangan Sudut';
      case 'Offsides':
        return 'Offside';
      case 'Blocked Shots':
        return 'Tembakan Diblokir';
      default:
        return statType;
    }
  }

  Widget _buildPredictionTab(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingPrediction) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prediction == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 64,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Prediksi tidak tersedia',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade300
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prediksi AI tersedia untuk pertandingan mendatang dari liga-liga top Eropa.\n\nGunakan algoritma canggih termasuk distribusi Poisson dan perbandingan statistik tim.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final predictions = _prediction!['predictions'] as Map<String, dynamic>?;
    final teams = _prediction!['teams'] as Map<String, dynamic>?;
    final comparison = _prediction!['comparison'] as Map<String, dynamic>?;

    if (predictions == null) {
      return const Center(child: Text('Data prediksi tidak lengkap'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildPredictionHeader(context),
          const SizedBox(height: 20),
          
          // Team Strength Comparison (Hexagonal Chart) - Moved to top
          if (comparison != null) ...[
            _buildStrengthComparison(context, comparison, teams),
            const SizedBox(height: 20),
          ],
          
          // Win Probability Card - Versus Style
          _buildVersusWinProbability(context, predictions, teams),
          const SizedBox(height: 20),
          
          // Goals & Under/Over Predictions
          _buildGoalsAndOverUnder(context, predictions),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPredictionHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Predictions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Analisis berdasarkan algoritma machine learning',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersusWinProbability(BuildContext context, Map<String, dynamic> predictions, Map<String, dynamic>? teams) {
    final theme = Theme.of(context);
    final winPercent = predictions['percent'] as Map<String, dynamic>?;
    
    final homeWin = double.tryParse(winPercent?['home']?.toString().replaceAll('%', '') ?? '0') ?? 0;
    final draw = double.tryParse(winPercent?['draw']?.toString().replaceAll('%', '') ?? '0') ?? 0;
    final awayWin = double.tryParse(winPercent?['away']?.toString().replaceAll('%', '') ?? '0') ?? 0;
    
    final winner = predictions['winner'] as Map<String, dynamic>?;
    final winnerName = winner?['name'] as String? ?? 'Unknown';
    final homeTeam = teams?['home']?['name'] ?? 'Home';
    final awayTeam = teams?['away']?['name'] ?? 'Away';

    // Determine winner for highlighting
    final isHomeWinner = homeWin > awayWin;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [Colors.indigo.shade900.withOpacity(0.3), Colors.purple.shade900.withOpacity(0.3)]
              : [Colors.indigo.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade100.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROBABILITAS KEMENANGAN',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.indigo.shade300
                              : Colors.indigo.shade800,
                        ),
                      ),
                      Text(
                        'Analisis berdasarkan performa tim',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Team names and logos
            Row(
              children: [
                // Home team
                Expanded(
                  child: Row(
                    children: [
                      if (teams?['home']?['logo'] != null)
                        CachedNetworkImage(
                          imageUrl: teams!['home']['logo'],
                          width: 28,
                          height: 28,
                          errorWidget: (context, url, error) => Icon(
                            Icons.shield,
                            size: 28,
                            color: Colors.blue.shade600,
                          ),
                        )
                      else
                        Icon(Icons.shield, size: 28, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          homeTeam,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.dark
                                ? Colors.blue.shade300
                                : Colors.blue.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // VS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'VS',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                // Away team
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          awayTeam,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.dark
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (teams?['away']?['logo'] != null)
                        CachedNetworkImage(
                          imageUrl: teams!['away']['logo'],
                          width: 28,
                          height: 28,
                          errorWidget: (context, url, error) => Icon(
                            Icons.shield,
                            size: 28,
                            color: Colors.red.shade600,
                          ),
                        )
                      else
                        Icon(Icons.shield, size: 28, color: Colors.red.shade600),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Independent percentage display for all values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.blue.shade800.withOpacity(0.3)
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.blue.shade600
                            : Colors.blue.shade300
                    ),
                  ),
                  child: Text(
                    '${homeWin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: theme.brightness == Brightness.dark
                          ? Colors.blue.shade200
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade700.withOpacity(0.3)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade500
                            : Colors.grey.shade300
                    ),
                  ),
                  child: Text(
                    '${draw.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey.shade200
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.red.shade800.withOpacity(0.3)
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.red.shade600
                            : Colors.red.shade300
                    ),
                  ),
                  child: Text(
                    '${awayWin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: theme.brightness == Brightness.dark
                          ? Colors.red.shade200
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Stacked probability bar
            Container(
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  // Home team bar
                  Row(
                    children: [
                      Expanded(
                        flex: homeWin.round(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.blue.shade700],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      // Draw section
                      Expanded(
                        flex: draw.round(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey.shade400, Colors.grey.shade600],
                            ),
                          ),
                        ),
                      ),
                      // Away team bar
                      Expanded(
                        flex: awayWin.round(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade700],
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // Winner prediction banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHomeWinner 
                      ? [Colors.blue.shade600, Colors.blue.shade800]
                      : [Colors.red.shade600, Colors.red.shade800],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (isHomeWinner ? Colors.blue : Colors.red).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREDIKSI AI',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '$winnerName Lebih Unggul',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsAndOverUnder(BuildContext context, Map<String, dynamic> predictions) {
    final theme = Theme.of(context);
    final goalsHome = predictions['goals']?['home'] as String?;
    final goalsAway = predictions['goals']?['away'] as String?;
    final underOver = predictions['under_over'] as String?;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.dark
              ? [theme.cardColor, theme.cardColor.withOpacity(0.8)]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - uniform with other cards
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREDIKSI GOL',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? Colors.deepOrange.shade300
                            : Colors.deepOrange.shade800,
                      ),
                    ),
                    Text(
                      'Prediksi skor dan total gol',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Compact two-column layout
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Prediksi Skor',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${goalsHome ?? '-'} vs ${goalsAway ?? '-'}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? Colors.indigo.shade300
                            : Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Under/Over 2.5',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      underOver ?? '-',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? Colors.orange.shade300
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthComparison(BuildContext context, Map<String, dynamic> comparison, Map<String, dynamic>? teams) {
    final theme = Theme.of(context);
    
    // Extract the key stats for hexagonal chart
    final stats = ['form', 'att', 'def', 'poisson_distribution', 'h2h', 'goals'];
    List<double> homeValues = [];
    List<double> awayValues = [];
    List<String> labels = [];
    
    for (String stat in stats) {
      if (comparison.containsKey(stat)) {
        final value = comparison[stat] as Map<String, dynamic>;
        final home = value['home']?.toString().replaceAll('%', '') ?? '0';
        final away = value['away']?.toString().replaceAll('%', '') ?? '0';
        
        homeValues.add(double.tryParse(home) ?? 0);
        awayValues.add(double.tryParse(away) ?? 0);
        labels.add(_formatComparisonLabel(stat));
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.indigo.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERBANDINGAN KEKUATAN TIM',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.indigo.shade300
                              : Colors.indigo.shade800,
                        ),
                      ),
                      Text(
                        'Analisis berdasarkan statistik tim',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Hexagonal Radar Chart
            if (homeValues.isNotEmpty && awayValues.isNotEmpty) ...[
              SizedBox(
                height: 300,
                child: CustomPaint(
                  painter: HexagonalRadarChartPainter(
                    homeValues: homeValues,
                    awayValues: awayValues,
                    labels: labels,
                    homeColor: Colors.blue.shade600,
                    awayColor: Colors.red.shade600,
                  ),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 20),
              
              // Team legends
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        teams?['home']?['name'] ?? 'Home',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        teams?['away']?['name'] ?? 'Away',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ] else
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Text(
                  'No comparison data available',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatComparisonLabel(String key) {
    switch (key) {
      case 'form':
        return 'Performa';
      case 'att':
        return 'Serangan';
      case 'def':
        return 'Pertahanan';
      case 'poisson_distribution':
        return 'Poisson';
      case 'h2h':
        return 'H2H';
      case 'goals':
        return 'Gol';
      case 'total':
        return 'Total';
      default:
        return key;
    }
  }

  Widget _buildStatusBadge(
      BuildContext context, bool isLive, bool isFinished) {
    final theme = Theme.of(context);
    Color bgColor;
    Color textColor;
    String text;

    if (isLive) {
      bgColor = Colors.red;
      textColor = Colors.white;
      // Make status more readable
      switch (widget.fixture.status.short) {
        case '1H':
          text = 'Babak Pertama';
          break;
        case '2H':
          text = 'Babak Kedua';
          break;
        case 'HT':
          text = 'Istirahat';
          break;
        case 'ET':
          text = 'Extra Time';
          break;
        case 'P':
          text = 'Penalty';
          break;
        default:
          text = 'LIVE';
      }
    } else if (isFinished) {
      bgColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
      text = 'Selesai';
    } else {
      bgColor = theme.primaryColor.withOpacity(0.1);
      textColor = theme.primaryColor;
      text = 'Belum Dimulai';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isLive && widget.fixture.status.elapsed != null) ...[
            const SizedBox(width: 4),
            Text(
              "${widget.fixture.status.elapsed}'",
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeam(BuildContext context, String name, String logo, TeamModel team) {
    final theme = Theme.of(context);
    final isHome = team.id == widget.fixture.homeTeam.id;
    final teamForm = isHome ? _homeTeamForm : _awayTeamForm;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(team: team),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CachedNetworkImage(
              imageUrl: logo,
              width: 80,
              height: 80,
              errorWidget: (_, __, ___) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_soccer, size: 40),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Form badges
            if (_isLoadingForm)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (teamForm.isNotEmpty)
              _buildFormBadges(teamForm, team.id),
          ],
        ),
      ),
    );
  }

  Widget _buildFormBadges(List<FixtureModel> fixtures, int teamId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: fixtures.map((fixture) {
        // Determine result for this team
        String result = 'D'; // Default draw
        Color color = Colors.grey;
        
        if (fixture.isFinished && fixture.homeGoals != null && fixture.awayGoals != null) {
          if (fixture.homeTeam.id == teamId) {
            // This team was home
            if (fixture.homeGoals! > fixture.awayGoals!) {
              result = 'W';
              color = Colors.green;
            } else if (fixture.homeGoals! < fixture.awayGoals!) {
              result = 'L';
              color = Colors.red;
            } else {
              result = 'D';
              color = Colors.orange;
            }
          } else {
            // This team was away
            if (fixture.awayGoals! > fixture.homeGoals!) {
              result = 'W';
              color = Colors.green;
            } else if (fixture.awayGoals! < fixture.homeGoals!) {
              result = 'L';
              color = Colors.red;
            } else {
              result = 'D';
              color = Colors.orange;
            }
          }
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: InkWell(
            onTap: () {
              // Navigate to match detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailScreen(fixture: fixture),
                ),
              );
            },
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScore(BuildContext context, bool isLive, bool isFinished) {
    final theme = Theme.of(context);
    final hasScore = widget.fixture.homeGoals != null && widget.fixture.awayGoals != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (hasScore) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.fixture.homeGoals}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLive ? Colors.red : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '-',
                    style: theme.textTheme.displayMedium,
                  ),
                ),
                Text(
                  '${widget.fixture.awayGoals}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLive ? Colors.red : null,
                  ),
                ),
              ],
            ),
            if (widget.fixture.halftimeHome != null && widget.fixture.halftimeAway != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'HT ${widget.fixture.halftimeHome}-${widget.fixture.halftimeAway}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ] else ...[
            Text(
              'VS',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchInfo(BuildContext context) {
    final theme = Theme.of(context);
    final localDate = widget.fixture.date.toLocal();
    
    final weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    
    final weekday = weekdays[localDate.weekday - 1];
    final day = localDate.day.toString().padLeft(2, '0');
    final month = months[localDate.month - 1];
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    
    final dateString = '$weekday, $day $month $year • $hour:$minute';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              dateString,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        if (widget.fixture.league.round != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.fixture.league.round!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for hexagonal radar chart
class HexagonalRadarChartPainter extends CustomPainter {
  final List<double> homeValues;
  final List<double> awayValues;
  final List<String> labels;
  final Color homeColor;
  final Color awayColor;

  HexagonalRadarChartPainter({
    required this.homeValues,
    required this.awayValues,
    required this.labels,
    required this.homeColor,
    required this.awayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw hexagon grid lines
    _drawHexagonGrid(canvas, center, radius, paint);
    
    // Draw labels
    _drawLabels(canvas, center, radius, size);
    
    // Draw data polygons
    _drawDataPolygon(canvas, center, radius, homeValues, homeColor, 0.3);
    _drawDataPolygon(canvas, center, radius, awayValues, awayColor, 0.3);
    
    // Draw data outlines
    _drawDataPolygon(canvas, center, radius, homeValues, homeColor, 1.0, strokeOnly: true);
    _drawDataPolygon(canvas, center, radius, awayValues, awayColor, 1.0, strokeOnly: true);
  }

  void _drawHexagonGrid(Canvas canvas, Offset center, double radius, Paint paint) {
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 1;

    // Draw concentric hexagons
    for (int i = 1; i <= 5; i++) {
      final hexRadius = radius * i / 5;
      _drawHexagon(canvas, center, hexRadius, paint);
    }

    // Draw radial lines
    paint.color = Colors.grey.shade300;
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * (3.14159 / 180);
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * (3.14159 / 180);
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, Size size) {
    for (int i = 0; i < labels.length && i < 6; i++) {
      final angle = (i * 60 - 90) * (3.14159 / 180);
      final labelRadius = radius + 10; // Much smaller gap from chart
      final labelPoint = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.white, // White labels work better on dark background
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      // Precise position adjustment based on hexagon vertex position
      double offsetX;
      double offsetY;
      
      switch (i) {
        case 0: // Top vertex (Performa) - 12 o'clock
          offsetX = -textPainter.width / 2;
          offsetY = -textPainter.height - 5;
          break;
        case 1: // Top-right vertex - 2 o'clock 
          offsetX = 5;
          offsetY = -textPainter.height / 2;
          break;
        case 2: // Bottom-right vertex - 4 o'clock
          offsetX = 5;
          offsetY = -textPainter.height / 2;
          break;
        case 3: // Bottom vertex (Poisson) - 6 o'clock
          offsetX = -textPainter.width / 2;
          offsetY = 5;
          break;
        case 4: // Bottom-left vertex - 8 o'clock
          offsetX = -textPainter.width - 5;
          offsetY = -textPainter.height / 2;
          break;
        case 5: // Top-left vertex - 10 o'clock
          offsetX = -textPainter.width - 5;
          offsetY = -textPainter.height / 2;
          break;
        default:
          offsetX = -textPainter.width / 2;
          offsetY = -textPainter.height / 2;
      }

      textPainter.paint(
        canvas,
        Offset(labelPoint.dx + offsetX, labelPoint.dy + offsetY),
      );
    }
  }

  void _drawDataPolygon(Canvas canvas, Offset center, double radius, List<double> values, Color color, double alpha, {bool strokeOnly = false}) {
    if (values.length < 3) return;

    final paint = Paint()
      ..color = strokeOnly ? color : color.withOpacity(alpha)
      ..style = strokeOnly ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = strokeOnly ? 3 : 1;

    final path = Path();
    for (int i = 0; i < values.length && i < 6; i++) {
      final angle = (i * 60 - 90) * (3.14159 / 180);
      final valueRadius = radius * (values[i] / 100); // Normalize to 0-100
      final point = Offset(
        center.dx + valueRadius * cos(angle),
        center.dy + valueRadius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Custom painter for football field markings
class FieldPainter extends CustomPainter {
  final Color lineColor;

  FieldPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      50,
      paint,
    );
    
    // Center dot
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      Paint()..color = lineColor..style = PaintingStyle.fill,
    );

    // Center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Penalty areas
    final penaltyWidth = size.width * 0.6;
    final penaltyHeight = 80.0;
    
    // Top penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        0,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Bottom penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        size.height - penaltyHeight,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Goal areas
    final goalWidth = size.width * 0.3;
    final goalHeight = 40.0;
    
    // Top goal area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalWidth) / 2,
        0,
        goalWidth,
        goalHeight,
      ),
      paint,
    );

    // Bottom goal area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalWidth) / 2,
        size.height - goalHeight,
        goalWidth,
        goalHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
