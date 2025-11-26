import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/game.dart';
import '../../core/models/user_game.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  final SwipableStackController _controller = SwipableStackController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSwipe(Game game, SwipeDirection direction) async {
    final userId = authRepository.currentUserId;
    if (userId == null) return;

    String? status;
    if (direction == SwipeDirection.right) {
      status = 'planned'; // chcę zagrać
    } else if (direction == SwipeDirection.left) {
      status = 'not_interested'; // nie pokazujemy nigdzie, tylko zapis
    } else {
      return;
    }

    final existing = await userGamesRepository.getUserGame(
      userId: userId,
      gameId: game.id,
    );

    final userGame = UserGame(
      id: existing?.id ?? '',
      userId: userId,
      gameId: game.id,
      status: status,
      rating: existing?.rating,
      note: existing?.note,
    );

    await userGamesRepository.upsertUserGame(userGame);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Game>>(
      stream: gamesRepository.watchAllGames(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('games.error_loading'.tr()),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final games = snapshot.data!;
        if (games.isEmpty) {
          return Center(
            child: Text('for_you.no_games'.tr()),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SwipableStack(
                  controller: _controller,
                  detectableSwipeDirections: const {
                    SwipeDirection.left,
                    SwipeDirection.right,
                  },
                  onSwipeCompleted: (index, direction) async {
                    if (index < 0 || index >= games.length) return;
                    final game = games[index];
                    await _handleSwipe(game, direction);
                  },
                  itemCount: games.length,
                  builder: (context, properties) {
                    final game = games[properties.index];
                    return _buildGameCard(game);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildButtonsRow(games),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildGameCard(Game game) {
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Obrazek
          Expanded(
            child: game.coverUrl.isNotEmpty
                ? Image.network(
                    game.coverUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackCover(),
                  )
                : _fallbackCover(),
          ),
          // Informacje
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${game.year} • ${game.genre}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                if (game.platforms.isNotEmpty)
                  Text(
                    game.platforms.join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                if (game.description.isNotEmpty)
                  Text(
                    game.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(
        Icons.videogame_asset,
        size: 64,
      ),
    );
  }

  Widget _buildButtonsRow(List<Game> games) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Nie interesuje mnie
        ElevatedButton.icon(
          onPressed: () {
            if (_controller.currentIndex >= games.length) return;
            _controller.next(swipeDirection: SwipeDirection.left);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          icon: const Icon(Icons.close),
          label: Text('for_you.button_dislike'.tr()),
        ),
        // Chcę zagrać
        ElevatedButton.icon(
          onPressed: () {
            if (_controller.currentIndex >= games.length) return;
            _controller.next(swipeDirection: SwipeDirection.right);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          icon: const Icon(Icons.favorite),
          label: Text('for_you.button_like'.tr()),
        ),
      ],
    );
  }
}
