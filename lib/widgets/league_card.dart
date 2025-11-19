import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// League Quick Access Card - Compact chip style
class LeagueCard extends StatelessWidget {
  final int leagueId;
  final String name;
  final String logo;
  final VoidCallback onTap;

  const LeagueCard({
    Key? key,
    required this.leagueId,
    required this.name,
    required this.logo,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // League logo
                CachedNetworkImage(
                  imageUrl: logo,
                  width: 24,
                  height: 24,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.sports_soccer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                // League name
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Predefined league configurations
class LeagueConfig {
  final int id;
  final String name;
  final String logo;

  const LeagueConfig({
    required this.id,
    required this.name,
    required this.logo,
  });

  /// Get current season based on current date
  /// European leagues: Aug-May (season year = start year)
  /// If current month >= 8 (August), use current year
  /// If current month < 8, use previous year
  int get season {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    // European leagues start in August
    // If we're in Aug-Dec, it's the current year season
    // If we're in Jan-Jul, it's the previous year season
    return currentMonth >= 8 ? currentYear : currentYear - 1;
  }

  static const premierLeague = LeagueConfig(
    id: 39,
    name: 'Premier League',
    logo: 'https://media.api-sports.io/football/leagues/39.png',
  );

  static const laLiga = LeagueConfig(
    id: 140,
    name: 'La Liga',
    logo: 'https://media.api-sports.io/football/leagues/140.png',
  );

  static const serieA = LeagueConfig(
    id: 135,
    name: 'Serie A',
    logo: 'https://media.api-sports.io/football/leagues/135.png',
  );

  static const bundesliga = LeagueConfig(
    id: 78,
    name: 'Bundesliga',
    logo: 'https://media.api-sports.io/football/leagues/78.png',
  );

  static const ligue1 = LeagueConfig(
    id: 61,
    name: 'Ligue 1',
    logo: 'https://media.api-sports.io/football/leagues/61.png',
  );

  static const ligaIndonesia = LeagueConfig(
    id: 274,
    name: 'Liga Indonesia',
    logo: 'https://media.api-sports.io/football/leagues/274.png',
  );

  static const championsLeague = LeagueConfig(
    id: 2,
    name: 'Champions League',
    logo: 'https://media.api-sports.io/football/leagues/2.png',
  );

  static const europaLeague = LeagueConfig(
    id: 3,
    name: 'Europa League',
    logo: 'https://media.api-sports.io/football/leagues/3.png',
  );

  /// All featured leagues
  static const allLeagues = [
    ligaIndonesia, // Indonesia first!
    premierLeague,
    laLiga,
    serieA,
    bundesliga,
    ligue1,
    championsLeague,
    europaLeague,
  ];
}
