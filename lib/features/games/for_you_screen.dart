import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/di/service_locator.dart';
import '../../core/api/rawg_client.dart';
import '../../core/models/rawg_game.dart';
import '../../core/models/user_game.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  final SwipableStackController _controller = SwipableStackController();
  final RawgClient _rawgClient = RawgClient();

  List<RawgGame> _games = [];
  bool _isLoading = false;
  String? _error;

  /// Wszystkie gry usera z Firestore (dla preferencji)
  List<UserGame> _userGames = [];

  /// Id gier, które user już „tknął” (swipe / zapis)
  Set<int> _seenGameIds = {};

  /// Preferencje gatunków wyliczone z dziennika
  Map<String, int> _likedGenres = {};
  Map<String, int> _dislikedGenres = {};

  /// Dane do cofnięcia ostatniego swipe'a
  int? _lastSwipedGameId;
  String? _lastPreviousStatus;
  int? _lastPreviousRating;
  String? _lastPreviousNote;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadUserDataAndPreferences();

      final games = await _rawgClient.fetchPopularGames();

      // odrzucamy gry, które user już ocenił / przesunął / zapisał
      final filtered = games
          .where((g) => !_seenGameIds.contains(g.id))
          .toList();

      // sortowanie wg prostego score (rating RAWG + preferencje gatunków)
      filtered.sort((a, b) =>
          _scoreForGame(b).compareTo(_scoreForGame(a)));

      if (!mounted) return;
      setState(() => _games = filtered);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Pobiera wszystkie gry usera i na ich podstawie wylicza preferencje
  Future<void> _loadUserDataAndPreferences() async {
    final userId = authRepository.currentUserId;
    if (userId == null) {
      _userGames = [];
      _seenGameIds = {};
      _likedGenres = {};
      _dislikedGenres = {};
      return;
    }

    final allUserGames = await userGamesRepository.getAllForUser(userId);

    _userGames = allUserGames;
    _seenGameIds = allUserGames.map((ug) => ug.gameId).toSet();

    _recomputePreferences();
  }

  /// Wyliczamy które gatunki lubisz, a których unikasz
  void _recomputePreferences() {
    final Map<String, int> liked = {};
    final Map<String, int> disliked = {};

    for (final ug in _userGames) {
      final genre = ug.genre;
      if (genre == null || genre.isEmpty) continue;

      final rating = ug.rating;

      final isLikedStatus =
          ug.status == 'planned' ||
          ug.status == 'playing' ||
          ug.status == 'finished';

      final isDislikedStatus = ug.status == 'not_interested';

      final isHighRating = rating != null && rating >= 4;
      final isLowRating = rating != null && rating <= 2;

      if (isLikedStatus || isHighRating) {
        liked[genre] = (liked[genre] ?? 0) + 1;
      }

      if (isDislikedStatus || isLowRating) {
        disliked[genre] = (disliked[genre] ?? 0) + 1;
      }
    }

    setState(() {
      _likedGenres = liked;
      _dislikedGenres = disliked;
    });
  }

  /// Prosty score gry na podstawie ratingu RAWG i Twoich gatunków
  double _scoreForGame(RawgGame game) {
    double score = (game.rating ?? 0);

    for (final genre in game.genres) {
      final likeCount = _likedGenres[genre] ?? 0;
      final dislikeCount = _dislikedGenres[genre] ?? 0;

      // za każdy „like” gatunku dodajemy punkt
      score += likeCount * 1.5;
      // za każdy „dislike” tego gatunku odejmujemy
      score -= dislikeCount * 2.0;
    }

    return score;
  }

  Future<void> _handleSwipe(
      RawgGame game, SwipeDirection direction) async {
    final userId = authRepository.currentUserId;
    if (userId == null) return;

    String? status;
    if (direction == SwipeDirection.right) {
      status = 'planned'; // lubisz, chcesz zagrać
    } else if (direction == SwipeDirection.left) {
      status = 'not_interested'; // nie interesuje Cię
    } else {
      return;
    }

    final existing = await userGamesRepository.getUserGame(
      userId: userId,
      gameId: game.id,
    );

    // zapamiętujemy stan sprzed swipe'a (do cofnięcia)
    _lastSwipedGameId = game.id;
    _lastPreviousStatus = existing?.status;
    _lastPreviousRating = existing?.rating;
    _lastPreviousNote = existing?.note;

    final userGame = UserGame(
      id: existing?.id ?? '',
      userId: userId,
      gameId: game.id,
      title: game.name,
      coverUrl: game.backgroundImage ?? '',
      year: game.year,
      genre: game.genres.isNotEmpty ? game.genres.first : null,
      status: status,
      rating: existing?.rating,
      note: existing?.note,
    );

    await userGamesRepository.upsertUserGame(userGame);

    setState(() {
      _seenGameIds.add(game.id);
      // aktualizujemy lokalną listę do preferencji
      _userGames.removeWhere((ug) => ug.gameId == game.id);
      _userGames.add(userGame);
    });

    // przelicz preferencje po nowej decyzji
    _recomputePreferences();
  }

  Future<void> _undoLastSwipe() async {
    final userId = authRepository.currentUserId;
    if (userId == null) return;
    if (_lastSwipedGameId == null) return;

    final lastGameId = _lastSwipedGameId!;
    final current = await userGamesRepository.getUserGame(
      userId: userId,
      gameId: lastGameId,
    );

    if (current == null) {
      _clearUndoState();
      return;
    }

    if (_lastPreviousStatus == null) {
      // wcześniej nie było wpisu – usuń
      await userGamesRepository.deleteUserGame(current.id);
      setState(() {
        _seenGameIds.remove(lastGameId);
        _userGames.removeWhere((ug) => ug.gameId == lastGameId);
      });
    } else {
      // przywróć poprzedni stan
      final restored = UserGame(
        id: current.id,
        userId: current.userId,
        gameId: current.gameId,
        title: current.title,
        coverUrl: current.coverUrl,
        year: current.year,
        genre: current.genre,
        status: _lastPreviousStatus!,
        rating: _lastPreviousRating,
        note: _lastPreviousNote,
      );
      await userGamesRepository.upsertUserGame(restored);

      setState(() {
        _userGames.removeWhere((ug) => ug.gameId == lastGameId);
        _userGames.add(restored);
      });
    }

    _recomputePreferences();
    _controller.rewind();
    _clearUndoState();
  }

  void _clearUndoState() {
    _lastSwipedGameId = null;
    _lastPreviousStatus = null;
    _lastPreviousRating = null;
    _lastPreviousNote = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_games.isEmpty) {
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
                if (index < 0 || index >= _games.length) return;
                final game = _games[index];
                await _handleSwipe(game, direction);
              },
              itemCount: _games.length,
              builder: (context, properties) {
                final game = _games[properties.index];
                return _buildGameCard(game)
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .scale(
                      begin: const Offset(0.97, 0.97),
                      curve: Curves.easeOut,
                    );
              },
              // overlay – wielkie X / serce na środku obrazka
              overlayBuilder: (context, properties) {
                final dir = properties.direction;
                final progress = properties.swipeProgress;
                if (dir == null || progress == 0) {
                  return const SizedBox.shrink();
                }

                final opacity = (progress.abs()).clamp(0.0, 1.0);

                IconData? icon;
                Color color;

                if (dir == SwipeDirection.right) {
                  icon = PhosphorIconsBold.heartStraight;
                  color = Colors.greenAccent;
                } else if (dir == SwipeDirection.left) {
                  icon = PhosphorIconsBold.x;
                  color = Colors.redAccent;
                } else {
                  return const SizedBox.shrink();
                }

                return Center(
                  child: Opacity(
                    opacity: opacity,
                    child: Icon(
                      icon,
                      color: color,
                      size: 100,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildButtonsRow(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGameCard(RawgGame game) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.95),
            theme.colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          children: [
            Expanded(
              child: game.backgroundImage != null
                  ? Image.network(
                      game.backgroundImage!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCover(),
                    )
                  : _fallbackCover(),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${game.year ?? ''}${game.year != null ? ' • ' : ''}'
                    '${game.genres.isNotEmpty ? game.genres.first : ''}',
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
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  if (game.rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${game.rating!.toStringAsFixed(1)} / 5',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      width: double.infinity,
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(
        PhosphorIconsBold.gameController,
        size: 64,
      ),
    );
  }

  Widget _buildButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // NIE INTERESUJE MNIE
          Expanded(
            child: _BigActionButton(
              color: Colors.redAccent,
              icon: PhosphorIconsBold.x,
              label: 'for_you.button_dislike'.tr(),
              onTap: () {
                _controller.next(swipeDirection: SwipeDirection.left);
              },
            ),
          ),
          const SizedBox(width: 12),
          // COFNIJ
          _BigRoundIconButton(
            icon: PhosphorIconsBold.arrowUDownLeft,
            tooltip: 'for_you.button_undo'.tr(),
            onTap: _undoLastSwipe,
          ),
          const SizedBox(width: 12),
          // CHCĘ ZAGRAĆ
          Expanded(
            child: _BigActionButton(
              color: Colors.greenAccent,
              icon: PhosphorIconsBold.heartStraight,
              label: 'for_you.button_like'.tr(),
              onTap: () {
                _controller.next(swipeDirection: SwipeDirection.right);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Duży, wypełniony przycisk akcji
class _BigActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: color.withOpacity(0.9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 4),
            const SizedBox(width: 4),
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      // tutaj możesz zmienić rozmiar czcionki:
                      // fontSize: 16,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Środkowy okrągły przycisk "cofnij"
class _BigRoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _BigRoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceVariant,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}
