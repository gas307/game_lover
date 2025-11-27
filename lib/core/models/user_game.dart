import 'package:cloud_firestore/cloud_firestore.dart';

class UserGame {
  final String id;        // id dokumentu w Firestore
  final String userId;
  final int gameId;       // ID gry z RAWG (int)
  final String title;     // snapshot
  final String coverUrl;
  final int? year;
  final String? genre;

  final String status;    // planned / playing / finished / not_interested
  final int? rating;      // twoja ocena
  final String? note;     // twoja notatka

  UserGame({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.title,
    required this.coverUrl,
    required this.status,
    this.year,
    this.genre,
    this.rating,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gameId': gameId,
      'title': title,
      'coverUrl': coverUrl,
      'year': year,
      'genre': genre,
      'status': status,
      'rating': rating,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserGame.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // gameId może być int albo string (ze starych danych)
    final dynamic rawGameId = data['gameId'];
    int parsedGameId;
    if (rawGameId is int) {
      parsedGameId = rawGameId;
    } else if (rawGameId is num) {
      parsedGameId = rawGameId.toInt();
    } else if (rawGameId is String) {
      parsedGameId = int.tryParse(rawGameId) ?? 0;
    } else {
      parsedGameId = 0;
    }

    return UserGame(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      gameId: parsedGameId,
      title: data['title'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
      year: (data['year'] as num?)?.toInt(),
      genre: data['genre'] as String?,
      status: data['status'] as String? ?? 'planned',
      rating: (data['rating'] as num?)?.toInt(),
      note: data['note'] as String?,
    );
  }
}
