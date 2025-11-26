import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UsersRepository {
  final FirebaseFirestore _db;
  UsersRepository(this._db);

  CollectionReference get _usersRef => _db.collection('users');

  Future<void> createUser({
    required String id,
    required String nickname,
    required String email,
  }) async {
    final user = AppUser(
      id: id,
      nickname: nickname,
      email: email,
      isAdmin: false,
    );
    await _usersRef.doc(id).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser?> getUser(String id) async {
    final doc = await _usersRef.doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<bool> isAdmin(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    return (data['isAdmin'] ?? false) as bool;
  }
}
