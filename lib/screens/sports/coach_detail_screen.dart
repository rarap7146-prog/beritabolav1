import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/football_api_service.dart';

/// Coach Detail Screen - Shows coach profile information
class CoachDetailScreen extends StatefulWidget {
  final int coachId;
  final String coachName;
  final String coachPhoto;
  final String teamName;
  final String teamLogo;

  const CoachDetailScreen({
    Key? key,
    required this.coachId,
    required this.coachName,
    required this.coachPhoto,
    required this.teamName,
    required this.teamLogo,
  }) : super(key: key);

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  final _apiService = FootballApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _coachData;

  @override
  void initState() {
    super.initState();
    _loadCoachData();
  }

  Future<void> _loadCoachData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _apiService.getCoachDetails(widget.coachId);
      
      if (response['results'] > 0 && response['response'] != null) {
        setState(() {
          _coachData = response['response'][0];
          _isLoading = false;
        });
        print('✅ Coach data loaded successfully');
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No data available for this coach';
        });
      }
    } catch (e) {
      print('❌ Error loading coach data: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load coach details';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Pelatih'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme)
              : RefreshIndicator(
                  onRefresh: _loadCoachData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildCoachHeader(isDark, theme),
                        if (_coachData != null) ...[
                          _buildPersonalInfo(isDark, theme),
                          _buildCareerInfo(isDark, theme),
                        ] else
                          _buildBasicInfo(isDark, theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load data',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCoachData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachHeader(bool isDark, ThemeData theme) {
    final coachPhoto = _coachData?['photo'] ?? widget.coachPhoto;
    final coachName = _coachData?['name'] ?? widget.coachName;
    final currentTeam = _coachData?['team'];
    final teamName = currentTeam?['name'] ?? widget.teamName;
    final teamLogo = currentTeam?['logo'] ?? widget.teamLogo;

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
          // Coach Photo with border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.amber.shade700,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade700.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundImage: coachPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(coachPhoto)
                  : null,
              child: coachPhoto.isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Coach Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coach Name
                Text(
                  coachName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports,
                        size: 14,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PELATIH KEPALA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Team Info
                Row(
                  children: [
                    if (teamLogo.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: teamLogo,
                        width: 20,
                        height: 20,
                        errorWidget: (_, __, ___) => const SizedBox(),
                      ),
                    if (teamLogo.isNotEmpty) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        teamName,
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

  Widget _buildPersonalInfo(bool isDark, ThemeData theme) {
    final firstname = _coachData?['firstname'] ?? '';
    final lastname = _coachData?['lastname'] ?? '';
    final nationality = _coachData?['nationality'] ?? '-';
    final birthDate = _coachData?['birth']?['date'] ?? '-';
    final birthPlace = _coachData?['birth']?['place'] ?? '-';
    final birthCountry = _coachData?['birth']?['country'] ?? '';
    final age = _coachData?['age']?.toString() ?? '-';
    final height = _coachData?['height'] ?? '-';
    final weight = _coachData?['weight'] ?? '-';

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
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informasi Pribadi',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (firstname.isNotEmpty || lastname.isNotEmpty) ...[
                  _buildInfoCard(
                    icon: Icons.badge_outlined,
                    title: 'Nama Lengkap',
                    value: '$firstname $lastname'.trim(),
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildInfoCard(
                  icon: Icons.flag_outlined,
                  title: 'Kebangsaan',
                  value: nationality,
                  color: Colors.green,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.cake_outlined,
                  title: 'Tanggal Lahir',
                  value: '$birthDate${age != '-' ? ' ($age tahun)' : ''}',
                  color: Colors.orange,
                  isDark: isDark,
                ),
                if (birthPlace.isNotEmpty && birthPlace != '-') ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Tempat Lahir',
                    value: birthCountry.isNotEmpty 
                        ? '$birthPlace, $birthCountry' 
                        : birthPlace,
                    color: Colors.purple,
                    isDark: isDark,
                  ),
                ],
                if (height != '-' || weight != '-') ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.accessibility_outlined,
                    title: 'Tinggi / Berat',
                    value: '$height / $weight',
                    color: Colors.teal,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerInfo(bool isDark, ThemeData theme) {
    final career = _coachData?['career'] as List<dynamic>?;
    
    if (career == null || career.isEmpty) {
      return _buildBasicInfo(isDark, theme);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            child: Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Riwayat Karir',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: career.length > 10 ? 10 : career.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = career[index];
              final teamName = item['team']?['name'] ?? '-';
              final teamLogo = item['team']?['logo'] ?? '';
              final start = item['start'] ?? '-';
              final end = item['end'] ?? 'Sekarang';
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (teamLogo.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: teamLogo,
                        width: 32,
                        height: 32,
                        errorWidget: (_, __, ___) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield, size: 20),
                        ),
                      )
                    else
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield, size: 20),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teamName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$start - $end',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (career.length > 10)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                '+ ${career.length - 10} tim lainnya',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(bool isDark, ThemeData theme) {
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
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informasi Pelatih',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoCard(
                  icon: Icons.assignment_ind_outlined,
                  title: 'Nama Lengkap',
                  value: widget.coachName,
                  color: Colors.blue,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.shield_outlined,
                  title: 'Tim Saat Ini',
                  value: widget.teamName,
                  color: Colors.green,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.badge_outlined,
                  title: 'ID Pelatih',
                  value: '#${widget.coachId}',
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail statistik pelatih tidak tersedia',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
