import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/game.dart';
import 'edit_game_screen.dart';

class AdminGamesScreen extends StatelessWidget {
  const AdminGamesScreen({super.key});
  static const routeName = '/admin';

  Future<bool> _isAdmin() async {
    final user = authRepository.currentUser;
    if (user == null) return false;
    return usersRepository.isAdmin(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == false) {
          return Scaffold(
            body: Center(child: Text('admin.no_access'.tr())),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('admin.title'.tr()),
            actions: [
              IconButton(
                icon: const Icon(Icons.cloud_upload),
                tooltip: 'admin.seed_tooltip'.tr(),
                onPressed: () async {
                  await gamesRepository.seedPopularGames();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('admin.seed_success'.tr()),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          // Jeśli kiedyś będziesz chciał z powrotem ręczne dodawanie gier,
          // po prostu odkomentuj ten fragment:
          /*
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EditGameScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          */

          body: StreamBuilder<List<Game>>(
            stream: gamesRepository.watchAllGames(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('admin.error_loading'.tr()));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final games = snapshot.data!;
              if (games.isEmpty) {
                return Center(child: Text('admin.no_games'.tr()));
              }

              return ListView.builder(
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return ListTile(
                    title: Text(game.title),
                    subtitle: Text('${game.year} • ${game.genre}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditGameScreen(game: game),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
