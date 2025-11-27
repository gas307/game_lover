import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_game.dart';

class UserGamesRepository {
  final CollectionReference<Map<String, dynamic>> _ref;

  UserGamesRepository(FirebaseFirestore firestore)
      : _ref = firestore.collection('userGames');

  Stream<List<UserGame>> watchUserGamesByStatus({
    required String userId,
    required String status,
  }) {
    return _ref
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snap) => snap.docs.map(UserGame.fromDoc).toList(),
        );
  }

  Future<UserGame?> getUserGame({
    required String userId,
    required int gameId,
  }) async {
    final query = await _ref
        .where('userId', isEqualTo: userId)
        .where('gameId', isEqualTo: gameId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return UserGame.fromDoc(query.docs.first);
  }

  Future<List<UserGame>> getAllForUser(String userId) async {
    final snap = await _ref.where('userId', isEqualTo: userId).get();
    return snap.docs.map(UserGame.fromDoc).toList();
  }

  Future<void> upsertUserGame(UserGame userGame) async {
    if (userGame.id.isEmpty) {
      await _ref.add(userGame.toMap());
    } else {
      await _ref.doc(userGame.id).set(
            userGame.toMap(),
            SetOptions(merge: true),
          );
    }
  }

  Future<void> deleteUserGame(String id) async {
    await _ref.doc(id).delete();
  }
}
