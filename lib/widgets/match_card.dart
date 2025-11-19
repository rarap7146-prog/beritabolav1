import 'package:flutter/material.dart';
import 'package:beritabola/models/fixture_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Match Card Widget - Shows fixture with teams, scores, status
class MatchCard extends StatelessWidget {
  final FixtureModel fixture;
  final VoidCallback? onTap;

  const MatchCard({
    Key? key,
    required this.fixture,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = fixture.isLive;
    final isFinished = fixture.isFinished;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // League info + Status
              Row(
                children: [
                  // League logo
                  CachedNetworkImage(
                    imageUrl: fixture.league.logo,
                    width: 20,
                    height: 20,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.sports_soccer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // League name
                  Expanded(
                    child: Text(
                      fixture.league.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(context, isLive, isFinished),
                ],
              ),
              const SizedBox(height: 12),
              // Teams and Score
              Row(
                children: [
                  // Home Team
                  Expanded(
                    child: _buildTeam(
                      context,
                      fixture.homeTeam.name,
                      fixture.homeTeam.logo,
                      true,
                    ),
                  ),
                  // Score
                  _buildScore(context, isLive, isFinished),
                  // Away Team
                  Expanded(
                    child: _buildTeam(
                      context,
                      fixture.awayTeam.name,
                      fixture.awayTeam.logo,
                      false,
                    ),
                  ),
                ],
              ),
              // Match time/date
              if (!isLive) ...[
                const SizedBox(height: 8),
                _buildMatchTime(context),
              ],
            ],
          ),
        ),
      ),
    );
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
      switch (fixture.status.short) {
        case '1H':
          text = 'Babak 1';
          break;
        case '2H':
          text = 'Babak 2';
          break;
        case 'HT':
          text = 'HT';
          break;
        case 'ET':
          text = 'Extra';
          break;
        case 'P':
          text = 'Penalti';
          break;
        default:
          text = fixture.status.short;
      }
      // Add elapsed time
      if (fixture.status.elapsed != null) {
        text += " ${fixture.status.elapsed}'";
      }
    } else if (isFinished) {
      bgColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
      text = 'FT';
    } else {
      bgColor = theme.primaryColor.withOpacity(0.1);
      textColor = theme.primaryColor;
      final localDate = fixture.date.toLocal();
      text = '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeam(
      BuildContext context, String name, String logo, bool isHome) {
    return Column(
      children: [
        // Team logo
        CachedNetworkImage(
          imageUrl: logo,
          width: 48,
          height: 48,
          errorWidget: (_, __, ___) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_soccer, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        // Team name
        Text(
          name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildScore(BuildContext context, bool isLive, bool isFinished) {
    final theme = Theme.of(context);
    final hasScore = fixture.homeGoals != null && fixture.awayGoals != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (hasScore) ...[
            // Score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${fixture.homeGoals}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLive ? Colors.red : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '-',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                Text(
                  '${fixture.awayGoals}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLive ? Colors.red : null,
                  ),
                ),
              ],
            ),
            // Halftime score
            if (fixture.halftimeHome != null && fixture.halftimeAway != null)
              Text(
                '(HT ${fixture.halftimeHome}-${fixture.halftimeAway})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
          ] else ...[
            // No score - show VS
            Text(
              'VS',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchTime(BuildContext context) {
    final theme = Theme.of(context);
    final localDate = fixture.date.toLocal();
    
    // Format date manually
    final weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    
    final weekday = weekdays[localDate.weekday - 1];
    final day = localDate.day.toString().padLeft(2, '0');
    final month = months[localDate.month - 1];
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    
    final dateString = '$weekday, $day $month $year • $hour:$minute';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          dateString,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
