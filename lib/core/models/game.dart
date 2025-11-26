import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String title;
  final int year;
  final String genre;
  final String description;
  final String coverUrl;
  final List<String> platforms;

  Game({
    required this.id,
    required this.title,
    required this.year,
    required this.genre,
    required this.description,
    required this.coverUrl,
    required this.platforms,
  });

  factory Game.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      title: data['title'] ?? '',
      year: (data['year'] ?? 0) is int
          ? data['year']
          : int.tryParse('${data['year']}') ?? 0,
      genre: data['genre'] ?? '',
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      platforms: (data['platforms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'year': year,
      'genre': genre,
      'description': description,
      'coverUrl': coverUrl,
      'platforms': platforms,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
