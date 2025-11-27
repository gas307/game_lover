import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/auth_repository.dart';
import '../repositories/users_repository.dart';
import '../repositories/user_games_repository.dart';

final firebaseAuth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

final authRepository = AuthRepository(firebaseAuth);
final usersRepository = UsersRepository(firestore);
final userGamesRepository = UserGamesRepository(firestore);
