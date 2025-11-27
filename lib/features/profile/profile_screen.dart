import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/user_game.dart';
import '../games/game_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _statuses = ['planned', 'playing', 'finished'];

  Stream<List<UserGame>> _userGamesStream(String status) {
    final userId = authRepository.currentUserId;
    if (userId == null) {
      return const Stream.empty();
    }
    return userGamesRepository.watchUserGamesByStatus(
      userId: userId,
      status: status,
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'playing':
        return 'game.status_playing'.tr();
      case 'finished':
        return 'game.status_finished'.tr();
      case 'planned':
      default:
        return 'game.status_planned'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authRepository.currentUser;

    if (user == null) {
      // raczej nie wystąpi dzięki AuthWrapper, ale na wszelki wypadek:
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'profile.login_to_see_diary'.tr(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: _statuses.length,
      child: Column(
        children: [
          // HEADER z avatarem i statystykami
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FutureBuilder<List<UserGame>>(
              future: userGamesRepository.getAllForUser(user.uid),
              builder: (context, snapshot) {
                final games = snapshot.data ?? const <UserGame>[];
                return _ProfileHeader(
                  email: user.email ?? '',
                  photoUrl: user.photoURL,
                  games: games,
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // Zakładki dziennika
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              isScrollable: false,
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              tabs: [
                Tab(text: 'profile.tab_planned'.tr()),
                Tab(text: 'profile.tab_playing'.tr()),
                Tab(text: 'profile.tab_finished'.tr()),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Zawartość zakładek
          Expanded(
            child: TabBarView(
              children: _statuses.map((status) {
                return StreamBuilder<List<UserGame>>(
                  stream: _userGamesStream(status),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'profile.error_loading'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userGames = snapshot.data!;
                    if (userGames.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'profile.empty_section'.tr(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: userGames.length,
                      itemBuilder: (context, index) {
                        final ug = userGames[index];
                        return _UserGameCard(
                          userGame: ug,
                          statusLabel: _statusLabel(ug.status),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    GameDetailScreen(rawgId: ug.gameId),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Górny header profilu z avatarem, mailem i statystykami
class _ProfileHeader extends StatelessWidget {
  final String email;
  final String? photoUrl;
  final List<UserGame> games;

  const _ProfileHeader({
    required this.email,
    required this.photoUrl,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = games.length;
    final planned =
        games.where((g) => g.status == 'planned').length;
    final playing =
        games.where((g) => g.status == 'playing').length;
    final finished =
        games.where((g) => g.status == 'finished').length;

    final ratedGames = games.where((g) => g.rating != null).toList();

    double? avgRating;
    if (ratedGames.isNotEmpty) {
      final total = ratedGames
          .map((g) => g.rating!.clamp(0, 5))         // normalizacja 0–5
          .fold<double>(0, (sum, r) => sum + r);     // suma jako double
      avgRating = total / ratedGames.length;         // średnia
    } else {
      avgRating = null;
    }


    final completion =
        total == 0 ? 0.0 : finished / total;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + email + liczba gier
            Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'profile.subtitle'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (total > 0)
                  Text(
                    '$total',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (total > 0) const SizedBox(width: 4),
                if (total > 0)
                  Text(
                    'profile.games_label'.tr(), // np. "gier"
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Małe "wykresy" – statystyki
            Row(
              children: [
                _StatChip(
                  label: 'profile.stat_planned'.tr(),
                  value: planned,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'profile.stat_playing'.tr(),
                  value: playing,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'profile.stat_finished'.tr(),
                  value: finished,
                  color: Colors.greenAccent,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pasek "postępu" ukończenia
            if (total > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'profile.progress'.tr(), // np. "Postęp ukończenia"
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '${(completion * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: completion,
                  minHeight: 6,
                ),
              ),
            ],

            // Średnia ocena (jeśli jest)
            if (avgRating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'profile.avg_rating'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '/ 5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Jeśli mamy zdjęcie z Google -> pokazujemy
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    // Domyślny avatar
    return const CircleAvatar(
      radius: 24,
      child: Icon(Icons.person, size: 26),
    );
  }
}

/// Mały "chip" statystyki, wygląda jak mini-wykres słupkowy
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Karta pojedynczej gry w dzienniku
class _UserGameCard extends StatelessWidget {
  final UserGame userGame;
  final String statusLabel;
  final VoidCallback onTap;

  const _UserGameCard({
    required this.userGame,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final infoLine = [
      if (userGame.year != null)
        '${userGame.year}${userGame.genre != null ? ' • ${userGame.genre}' : ''}',
      statusLabel,
    ].where((s) => s.isNotEmpty).join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildCover(),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: _buildInfo(context, infoLine),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    const double size = 72;

    if (userGame.coverUrl.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          width: size,
          height: size,
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(
            Icons.videogame_asset,
            size: 28,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Image.network(
        userGame.coverUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(
              Icons.videogame_asset,
              size: 28,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfo(BuildContext context, String infoLine) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          userGame.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (infoLine.isNotEmpty)
          Text(
            infoLine,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (userGame.rating != null)
              _RatingStars(rating: userGame.rating!),
            if (userGame.rating != null) const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Gwiazdki dla oceny użytkownika (0–5)
class _RatingStars extends StatelessWidget {
  final int rating; // 0–5

  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final stars = rating.clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: filled ? Colors.amber : Colors.grey,
        );
      }),
    );
  }
}
