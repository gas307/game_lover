import 'package:cloud_firestore/cloud_firestore.dart';

class UserGame {
  final String id;
  final String userId;
  final String gameId;
  final String status; // planned / playing / finished
  final int? rating;   // 1–10
  final String? note;

  UserGame({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.status,
    this.rating,
    this.note,
  });

  factory UserGame.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserGame(
      id: doc.id,
      userId: data['userId'] ?? '',
      gameId: data['gameId'] ?? '',
      status: data['status'] ?? 'planned',
      rating: data['rating'],
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gameId': gameId,
      'status': status,
      'rating': rating,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
