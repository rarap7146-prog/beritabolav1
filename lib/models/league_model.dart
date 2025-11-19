/// League/Competition Model for API-Football
class LeagueModel {
  final int id;
  final String name;
  final String country;
  final String logo;
  final String? flag;
  final int? season;
  final String? round;

  LeagueModel({
    required this.id,
    required this.name,
    required this.country,
    required this.logo,
    this.flag,
    this.season,
    this.round,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    return LeagueModel(
      id: json['id'] as int,
      name: json['name'] as String,
      country: json['country'] as String? ?? 'International',
      logo: json['logo'] as String,
      flag: json['flag'] as String?,
      season: json['season'] as int?,
      round: json['round'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'logo': logo,
        'flag': flag,
        'season': season,
        'round': round,
      };

  @override
  String toString() => 'LeagueModel(id: $id, name: $name, country: $country)';
}
