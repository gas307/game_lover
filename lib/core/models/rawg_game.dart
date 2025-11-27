class RawgGame {
  final int id;
  final String name;
  final String? backgroundImage;
  final DateTime? released;
  final List<String> genres;
  final List<String> platforms;
  final double? rating;
  final int? ratingsCount;
  final int? metacritic;
  final String? description; // tylko przy szczegółach

  RawgGame({
    required this.id,
    required this.name,
    this.backgroundImage,
    this.released,
    required this.genres,
    required this.platforms,
    this.rating,
    this.ratingsCount,
    this.metacritic,
    this.description,
  });

  int? get year => released?.year;

  factory RawgGame.fromListJson(Map<String, dynamic> json) {
    return RawgGame(
      id: json['id'] as int,
      name: json['name'] ?? '',
      backgroundImage: json['background_image'] as String?,
      released: _parseDate(json['released'] as String?),
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((g) => g['name'] as String? ?? '')
          .where((g) => g.isNotEmpty)
          .toList(),
      platforms: (json['platforms'] as List<dynamic>? ?? [])
          .map((p) => p['platform']?['name'] as String? ?? '')
          .where((p) => p.isNotEmpty)
          .toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      ratingsCount: json['ratings_count'] as int?,
      metacritic: json['metacritic'] as int?,
      description: null,
    );
  }

  factory RawgGame.fromDetailJson(Map<String, dynamic> json) {
    return RawgGame(
      id: json['id'] as int,
      name: json['name'] ?? '',
      backgroundImage: json['background_image'] as String?,
      released: _parseDate(json['released'] as String?),
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((g) => g['name'] as String? ?? '')
          .where((g) => g.isNotEmpty)
          .toList(),
      platforms: (json['platforms'] as List<dynamic>? ?? [])
          .map((p) => p['platform']?['name'] as String? ?? '')
          .where((p) => p.isNotEmpty)
          .toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      ratingsCount: json['ratings_count'] as int?,
      metacritic: json['metacritic'] as int?,
      description: json['description_raw'] as String?,
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}
