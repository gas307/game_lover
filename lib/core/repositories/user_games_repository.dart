import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_game.dart';

class UserGamesRepository {
  final FirebaseFirestore _db;
  UserGamesRepository(this._db);

  CollectionReference get _userGamesRef => _db.collection('userGames');

  Future<UserGame?> getUserGame({
    required String userId,
    required String gameId,
  }) async {
    final snap = await _userGamesRef
        .where('userId', isEqualTo: userId)
        .where('gameId', isEqualTo: gameId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return UserGame.fromDoc(snap.docs.first);
  }

  Future<void> upsertUserGame(UserGame userGame) async {
    if (userGame.id.isEmpty) {
      await _userGamesRef.add(userGame.toMap());
    } else {
      await _userGamesRef.doc(userGame.id).update(userGame.toMap());
    }
  }

  Stream<List<UserGame>> watchUserGamesByStatus({
    required String userId,
    required String status,
  }) {
    return _userGamesRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserGame.fromDoc(doc)).toList());
  }
}
