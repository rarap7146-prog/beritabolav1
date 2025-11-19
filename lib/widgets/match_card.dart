import 'dart:async';
import 'package:flutter/material.dart';
import 'package:beritabola/models/fixture_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beritabola/services/live_match_notification_service.dart';

/// Match Card Widget - Shows fixture with teams, scores, status
class MatchCard extends StatefulWidget {
  final FixtureModel fixture;
  final VoidCallback? onTap;
  final bool isRefreshing; // For showing refresh animation
  final bool showTrackButton; // Show button to track match in notification

  const MatchCard({
    Key? key,
    required this.fixture,
    this.onTap,
    this.isRefreshing = false,
    this.showTrackButton = false,
  }) : super(key: key);

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  StreamSubscription? _trackingStateSubscription;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Listen to tracking state changes
    final notificationService = LiveMatchNotificationService();
    _trackingStateSubscription = notificationService.trackingStateStream.listen((_) {
      if (mounted) setState(() {});
    });
    
    // Sync state on init to catch external stops
    notificationService.syncState();
    
    // Periodic sync every 2 seconds to catch notification dismissals
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        notificationService.syncState();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Sync state when app resumes from background
    if (state == AppLifecycleState.resumed) {
      LiveMatchNotificationService().syncState();
    }
  }

  @override
  void didUpdateWidget(MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _trackingStateSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = widget.fixture.isLive;
    final isFinished = widget.fixture.isFinished;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
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
                    imageUrl: widget.fixture.league.logo,
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
                      widget.fixture.league.name,
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
                      widget.fixture.homeTeam.name,
                      widget.fixture.homeTeam.logo,
                      true,
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
              // Track button for live matches
              if (isLive && widget.showTrackButton) ...[
                const SizedBox(height: 12),
                _buildTrackButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackButton(BuildContext context) {
    final notificationService = LiveMatchNotificationService();
    final isThisMatchTracked = notificationService.isTrackingMatch(widget.fixture.id);
    final isAnotherMatchTracked = notificationService.isTracking && !isThisMatchTracked;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          if (isThisMatchTracked) {
            // Stop tracking this match
            await notificationService.stopTracking();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Berhenti melacak pertandingan'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else if (isAnotherMatchTracked) {
            // Warn user about switching matches
            if (context.mounted) {
              final shouldSwitch = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ganti Pertandingan?'),
                  content: Text(
                    'Anda sudah melacak pertandingan lain. Ganti ke ${widget.fixture.homeTeam.name} vs ${widget.fixture.awayTeam.name}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ganti'),
                    ),
                  ],
                ),
              );
              
              if (shouldSwitch == true && context.mounted) {
                await notificationService.startTracking(widget.fixture);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Melacak: ${widget.fixture.homeTeam.name} vs ${widget.fixture.awayTeam.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
          } else {
            // Start tracking this match
            await notificationService.startTracking(widget.fixture);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Melacak: ${widget.fixture.homeTeam.name} vs ${widget.fixture.awayTeam.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
          setState(() {}); // Refresh button state
        },
        icon: Icon(
          isThisMatchTracked ? Icons.notifications_off : 
          isAnotherMatchTracked ? Icons.notifications_none : 
          Icons.notifications_active,
          size: 18,
        ),
        label: Text(
          isThisMatchTracked ? 'Berhenti Lacak' : 
          isAnotherMatchTracked ? 'Ganti Lacak' :
          'Lacak di Notifikasi',
          style: const TextStyle(fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          foregroundColor: isThisMatchTracked ? Colors.grey : 
                          isAnotherMatchTracked ? Colors.orange :
                          Colors.blue,
          side: BorderSide(
            color: isThisMatchTracked ? Colors.grey.shade400 : 
                   isAnotherMatchTracked ? Colors.orange.shade300 :
                   Colors.blue.shade300,
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
      switch (widget.fixture.status.short) {
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
          text = widget.fixture.status.short;
      }
      // Add elapsed time with refresh animation
      if (widget.fixture.status.elapsed != null) {
        text += " ${widget.fixture.status.elapsed}'";
      }
    } else if (isFinished) {
      bgColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
      text = 'FT';
    } else {
      bgColor = theme.primaryColor.withOpacity(0.1);
      textColor = theme.primaryColor;
      final localDate = widget.fixture.date.toLocal();
      text = '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    }

    // Wrap in FadeTransition for refresh animation (only for live matches)
    Widget badge = Container(
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
    
    // Apply fade animation during refresh for live matches
    if (isLive && widget.isRefreshing) {
      return FadeTransition(
        opacity: _pulseAnimation,
        child: badge,
      );
    }
    
    return badge;
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
    final hasScore = widget.fixture.homeGoals != null && widget.fixture.awayGoals != null;

    Widget scoreWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (hasScore) ...[
            // Score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.fixture.homeGoals}',
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
                  '${widget.fixture.awayGoals}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLive ? Colors.red : null,
                  ),
                ),
              ],
            ),
            // Halftime score
            if (widget.fixture.halftimeHome != null && widget.fixture.halftimeAway != null)
              Text(
                '(HT ${widget.fixture.halftimeHome}-${widget.fixture.halftimeAway})',
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
    
    // Apply pulsing animation during refresh for live matches
    if (isLive && widget.isRefreshing) {
      return FadeTransition(
        opacity: _pulseAnimation,
        child: scoreWidget,
      );
    }
    
    return scoreWidget;
  }

  Widget _buildMatchTime(BuildContext context) {
    final theme = Theme.of(context);
    final localDate = widget.fixture.date.toLocal();
    
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
