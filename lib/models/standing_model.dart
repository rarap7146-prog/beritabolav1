import 'package:beritabola/models/team_model.dart';

/// League Standing Model for API-Football
class StandingModel {
  final int rank;
  final TeamModel team;
  final int points;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final String? description;
  final String? group; // For tournament groups (Group A, Group B, etc.)

  StandingModel({
    required this.rank,
    required this.team,
    required this.points,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    this.description,
    this.group,
  });

  factory StandingModel.fromJson(Map<String, dynamic> json, {String? groupName}) {
    final all = json['all'] as Map<String, dynamic>;
    final goals = all['goals'] as Map<String, dynamic>;

    return StandingModel(
      rank: json['rank'] as int,
      team: TeamModel.fromJson(json['team'] as Map<String, dynamic>),
      points: json['points'] as int,
      matchesPlayed: all['played'] as int,
      wins: all['win'] as int,
      draws: all['draw'] as int,
      losses: all['lose'] as int,
      goalsFor: goals['for'] as int,
      goalsAgainst: goals['against'] as int,
      goalDifference: json['goalsDiff'] as int,
      description: json['description'] as String?,
      group: groupName, // Pass group info from API
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'team': team.toJson(),
        'points': points,
        'matchesPlayed': matchesPlayed,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'goalDifference': goalDifference,
        'description': description,
      };

  @override
  String toString() =>
      'StandingModel(rank: $rank, team: ${team.name}, points: $points)';
}
