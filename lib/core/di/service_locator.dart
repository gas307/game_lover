import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/auth_repository.dart';
import '../repositories/users_repository.dart';
import '../repositories/games_repository.dart';
import '../repositories/user_games_repository.dart';

final authRepository = AuthRepository(FirebaseAuth.instance);
final usersRepository = UsersRepository(FirebaseFirestore.instance);
final gamesRepository = GamesRepository(FirebaseFirestore.instance);
final userGamesRepository = UserGamesRepository(FirebaseFirestore.instance);
