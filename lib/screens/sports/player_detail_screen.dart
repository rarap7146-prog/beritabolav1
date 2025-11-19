import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../providers/football_provider.dart';

/// Player Detail Screen - Shows comprehensive player profile and statistics
class PlayerDetailScreen extends StatefulWidget {
  final int playerId;
  final String playerName;
  final String playerPhoto;
  final String teamName;
  final String teamLogo;

  const PlayerDetailScreen({
    Key? key,
    required this.playerId,
    required this.playerName,
    required this.playerPhoto,
    required this.teamName,
    required this.teamLogo,
  }) : super(key: key);

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  Map<String, dynamic>? _playerData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = Provider.of<FootballProvider>(context, listen: false);
    
    // Get current season (same logic as league cards)
    final now = DateTime.now();
    final season = now.month >= 8 ? now.year : now.year - 1;
    
    try {
      final data = await provider.fetchPlayerDetails(
        playerId: widget.playerId,
        season: season,
      );
      
      if (mounted) {
        setState(() {
          _playerData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data pemain';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detil Pemain'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _playerData == null
                  ? _buildNoDataState()
                  : RefreshIndicator(
                      onRefresh: _loadPlayerData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildPlayerHeader(isDark, theme),
                            _buildPlayerInfo(isDark, theme),
                            _buildCurrentSeasonStats(isDark, theme),
                            _buildCareerStats(isDark, theme),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_error ?? 'Terjadi kesalahan', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPlayerData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Data pemain tidak tersedia', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(bool isDark, ThemeData theme) {
    final player = _playerData!['player'] as Map<String, dynamic>;
    
    // Get photo from loaded player data (API), fallback to widget parameter
    final playerPhoto = (player['photo'] as String?) ?? widget.playerPhoto;
    
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
          // Player Photo with border (smaller)
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
            child: CircleAvatar(
              radius: 40,
              backgroundImage: playerPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(playerPhoto)
                  : null,
              child: playerPhoto.isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player Name
                Text(
                  player['name'] ?? widget.playerName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Team Info
                Row(
                  children: [
                    if (widget.teamLogo.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: widget.teamLogo,
                        width: 20,
                        height: 20,
                        errorWidget: (_, __, ___) => const SizedBox(),
                      ),
                    if (widget.teamLogo.isNotEmpty) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.teamName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(bool isDark, ThemeData theme) {
    final player = _playerData!['player'] as Map<String, dynamic>;
    
    final age = player['age']?.toString() ?? '-';
    final nationality = player['nationality'] ?? '-';
    final height = player['height'] ?? '-';
    final weight = player['weight'] ?? '-';
    
    final statistics = _playerData!['statistics'] as List?;
    final position = statistics != null && statistics.isNotEmpty
        ? (statistics[0]['games']?['position'] ?? '-')
        : '-';

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
              'Informasi Pemain',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildInfoRow(Icons.cake_outlined, 'Usia', age, isDark),
          _buildInfoRow(Icons.flag_outlined, 'Kebangsaan', nationality, isDark),
          _buildInfoRow(Icons.sports_soccer_outlined, 'Posisi', position, isDark),
          _buildInfoRow(Icons.height_outlined, 'Tinggi', height, isDark),
          _buildInfoRow(Icons.fitness_center_outlined, 'Berat', weight, isDark),
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
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSeasonStats(bool isDark, ThemeData theme) {
    final statistics = _playerData!['statistics'] as List?;
    
    if (statistics == null || statistics.isEmpty) {
      return const SizedBox();
    }

    final stats = statistics[0] as Map<String, dynamic>;
    final games = stats['games'] as Map<String, dynamic>?;
    final goals = stats['goals'] as Map<String, dynamic>?;
    final cards = stats['cards'] as Map<String, dynamic>?;
    final passes = stats['passes'] as Map<String, dynamic>?;
    final tackles = stats['tackles'] as Map<String, dynamic>?;
    final duels = stats['duels'] as Map<String, dynamic>?;

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
              'Statistik Musim Ini',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Performance Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '⚽',
                        'Gol',
                        '${goals?['total'] ?? 0}',
                        theme.primaryColor,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '🎯',
                        'Assist',
                        '${goals?['assists'] ?? 0}',
                        Colors.green,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '🎮',
                        'Main',
                        '${games?['appearences'] ?? 0}',
                        Colors.blue,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Cards & Minutes
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '🟨',
                        'Kuning',
                        '${cards?['yellow'] ?? 0}',
                        Colors.yellow.shade700,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '🟥',
                        'Merah',
                        '${cards?['red'] ?? 0}',
                        Colors.red,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '⏱️',
                        'Menit',
                        '${games?['minutes'] ?? 0}',
                        Colors.orange,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Advanced Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '📊',
                        'Pass%',
                        '${passes?['accuracy'] ?? 0}',
                        Colors.purple,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '🛡️',
                        'Tackle',
                        '${tackles?['total'] ?? 0}',
                        Colors.teal,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '⚔️',
                        'Duel%',
                        '${duels?['won'] ?? 0}',
                        Colors.indigo,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerStats(bool isDark, ThemeData theme) {
    final player = _playerData!['player'] as Map<String, dynamic>;
    final birthDate = player['birth']?['date'];
    final birthPlace = player['birth']?['place'];
    final birthCountry = player['birth']?['country'];
    
    String birthInfo = '-';
    if (birthDate != null) {
      try {
        final date = DateTime.parse(birthDate);
        birthInfo = '${date.day}/${date.month}/${date.year}';
        if (birthPlace != null) birthInfo += ', $birthPlace';
        if (birthCountry != null) birthInfo += ', $birthCountry';
      } catch (e) {
        birthInfo = birthDate;
      }
    }

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
              'Informasi Tambahan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal Lahir', birthInfo, isDark),
          if (player['injured'] == true)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pemain sedang cedera',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

