/// Team Model for API-Football
class TeamModel {
  final int id;
  final String name;
  final String logo;
  final bool? winner;

  TeamModel({
    required this.id,
    required this.name,
    required this.logo,
    this.winner,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] as String,
      winner: json['winner'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'winner': winner,
      };

  @override
  String toString() => 'TeamModel(id: $id, name: $name)';
}
