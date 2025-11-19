import 'package:flutter/material.dart';
import 'package:beritabola/models/team_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../providers/football_provider.dart';
import 'player_detail_screen.dart';

/// Team Detail Screen - Shows comprehensive team information and squad
class TeamDetailScreen extends StatefulWidget {
  final TeamModel team;

  const TeamDetailScreen({
    Key? key,
    required this.team,
  }) : super(key: key);

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _teamInfo;
  List<dynamic> _squad = [];
  bool _isLoadingInfo = true;
  bool _isLoadingSquad = true;
  String? _error;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    final provider = Provider.of<FootballProvider>(context, listen: false);
    
    // Load team info
    setState(() => _isLoadingInfo = true);
    try {
      final info = await provider.fetchTeamInfo(widget.team.id);
      if (mounted) {
        setState(() {
          _teamInfo = info;
          _isLoadingInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat informasi tim';
          _isLoadingInfo = false;
        });
      }
    }

    // Load squad
    setState(() => _isLoadingSquad = true);
    try {
      final squad = await provider.fetchTeamSquad(widget.team.id);
      if (mounted) {
        setState(() {
          _squad = squad;
          _isLoadingSquad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSquad = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Tim'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : theme.primaryColor,
          tabs: const [
            Tab(text: 'Informasi'),
            Tab(text: 'Skuad'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(isDark, theme),
          _buildSquadTab(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildInfoTab(bool isDark, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadTeamData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildTeamHeader(isDark, theme),
            if (_isLoadingInfo)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              _buildErrorState()
            else if (_teamInfo != null)
              _buildTeamDetails(isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader(bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F2937), Colors.grey.shade900]
              : [theme.primaryColor.withOpacity(0.1), Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Team Logo
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.primaryColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: CachedNetworkImage(
              imageUrl: widget.team.logo,
              width: 60,
              height: 60,
              errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 60),
            ),
          ),
          const SizedBox(width: 16),
          // Team Name
          Expanded(
            child: Text(
              widget.team.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_error ?? 'Terjadi kesalahan', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTeamData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamDetails(bool isDark, ThemeData theme) {
    final team = _teamInfo!['team'] as Map<String, dynamic>;
    final venue = _teamInfo!['venue'] as Map<String, dynamic>?;

    final founded = team['founded']?.toString() ?? '-';
    final country = team['country'] ?? '-';
    final venueName = venue?['name'] ?? '-';
    final venueCity = venue?['city'] ?? '-';
    final venueCapacity = venue?['capacity']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Informasi Tim',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildInfoRow(Icons.flag_outlined, 'Negara', country, isDark),
          _buildInfoRow(Icons.calendar_today_outlined, 'Didirikan', founded, isDark),
          _buildInfoRow(Icons.stadium_outlined, 'Stadion', venueName, isDark),
          _buildInfoRow(Icons.location_city_outlined, 'Kota', venueCity, isDark),
          _buildInfoRow(Icons.people_outline, 'Kapasitas', venueCapacity, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadTab(bool isDark, ThemeData theme) {
    if (_isLoadingSquad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_squad.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Data skuad tidak tersedia', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    // Group players by position
    final goalkeepers = _squad.where((p) => p['position'] == 'Goalkeeper').toList();
    final defenders = _squad.where((p) => p['position'] == 'Defender').toList();
    final midfielders = _squad.where((p) => p['position'] == 'Midfielder').toList();
    final attackers = _squad.where((p) => p['position'] == 'Attacker').toList();

    return RefreshIndicator(
      onRefresh: _loadTeamData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (goalkeepers.isNotEmpty) ...[
            _buildPositionSection('🧤 Penjaga Gawang', goalkeepers, isDark, theme),
            const SizedBox(height: 16),
          ],
          if (defenders.isNotEmpty) ...[
            _buildPositionSection('🛡️ Bek', defenders, isDark, theme),
            const SizedBox(height: 16),
          ],
          if (midfielders.isNotEmpty) ...[
            _buildPositionSection('⚙️ Gelandang', midfielders, isDark, theme),
            const SizedBox(height: 16),
          ],
          if (attackers.isNotEmpty) ...[
            _buildPositionSection('⚡ Penyerang', attackers, isDark, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionSection(String title, List<dynamic> players, bool isDark, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...players.map((player) => _buildPlayerTile(player, isDark, theme)).toList(),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(Map<String, dynamic> player, bool isDark, ThemeData theme) {
    final name = player['name'] ?? 'Unknown';
    final number = player['number']?.toString() ?? '-';
    final age = player['age']?.toString() ?? '-';
    final photo = player['photo'] ?? '';

    return InkWell(
      onTap: () {
        if (player['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerDetailScreen(
                playerId: player['id'] as int,
                playerName: name,
                playerPhoto: photo,
                teamName: widget.team.name,
                teamLogo: widget.team.logo,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Player Number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Player Photo
            CircleAvatar(
              radius: 20,
              backgroundImage: photo.isNotEmpty
                  ? CachedNetworkImageProvider(photo)
                  : null,
              child: photo.isEmpty ? const Icon(Icons.person, size: 20) : null,
            ),
            const SizedBox(width: 12),
            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Usia: $age',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
