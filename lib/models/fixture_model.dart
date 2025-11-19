import 'package:beritabola/models/league_model.dart';
import 'package:beritabola/models/team_model.dart';

/// Fixture/Match Model for API-Football
class FixtureModel {
  final int id;
  final String? referee;
  final DateTime date;
  final int timestamp;
  final String venue;
  final String? city;
  final FixtureStatus status;
  final LeagueModel league;
  final TeamModel homeTeam;
  final TeamModel awayTeam;
  final int? homeGoals;
  final int? awayGoals;
  final int? halftimeHome;
  final int? halftimeAway;

  FixtureModel({
    required this.id,
    this.referee,
    required this.date,
    required this.timestamp,
    required this.venue,
    this.city,
    required this.status,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    this.homeGoals,
    this.awayGoals,
    this.halftimeHome,
    this.halftimeAway,
  });

  factory FixtureModel.fromJson(Map<String, dynamic> json) {
    final fixture = json['fixture'] as Map<String, dynamic>;
    final league = json['league'] as Map<String, dynamic>;
    final teams = json['teams'] as Map<String, dynamic>;
    final goals = json['goals'] as Map<String, dynamic>;
    final score = json['score'] as Map<String, dynamic>;

    return FixtureModel(
      id: fixture['id'] as int,
      referee: fixture['referee'] as String?,
      date: DateTime.parse(fixture['date'] as String), // Store UTC from API
      timestamp: fixture['timestamp'] as int,
      venue: fixture['venue']?['name'] ?? 'Unknown Venue',
      city: fixture['venue']?['city'] as String?,
      status: FixtureStatus.fromJson(fixture['status'] as Map<String, dynamic>),
      league: LeagueModel.fromJson(league),
      homeTeam: TeamModel.fromJson(teams['home'] as Map<String, dynamic>),
      awayTeam: TeamModel.fromJson(teams['away'] as Map<String, dynamic>),
      homeGoals: goals['home'] as int?,
      awayGoals: goals['away'] as int?,
      halftimeHome: score['halftime']?['home'] as int?,
      halftimeAway: score['halftime']?['away'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'referee': referee,
        'date': date.toIso8601String(),
        'timestamp': timestamp,
        'venue': venue,
        'city': city,
        'status': status.toJson(),
        'league': league.toJson(),
        'homeTeam': homeTeam.toJson(),
        'awayTeam': awayTeam.toJson(),
        'homeGoals': homeGoals,
        'awayGoals': awayGoals,
        'halftimeHome': halftimeHome,
        'halftimeAway': halftimeAway,
      };

  bool get isLive =>
      status.short == '1H' ||
      status.short == '2H' ||
      status.short == 'HT' ||
      status.short == 'ET' ||
      status.short == 'P';

  bool get isFinished =>
      status.short == 'FT' ||
      status.short == 'AET' ||
      status.short == 'PEN';

  bool get isScheduled =>
      status.short == 'TBD' ||
      status.short == 'NS';

  @override
  String toString() =>
      'FixtureModel(id: $id, ${homeTeam.name} vs ${awayTeam.name}, status: ${status.short})';
}

/// Fixture Status (match status)
class FixtureStatus {
  final String long;
  final String short;
  final int? elapsed;

  FixtureStatus({
    required this.long,
    required this.short,
    this.elapsed,
  });

  factory FixtureStatus.fromJson(Map<String, dynamic> json) {
    return FixtureStatus(
      long: json['long'] as String,
      short: json['short'] as String,
      elapsed: json['elapsed'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'long': long,
        'short': short,
        'elapsed': elapsed,
      };

  @override
  String toString() => 'FixtureStatus($short${elapsed != null ? " $elapsed'" : ""})';
}
