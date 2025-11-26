import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/game.dart';
import '../../core/models/user_game.dart';
import '../../core/theme/theme_provider.dart';
import '../games/game_detail_screen.dart';
import '../games/widgets/game_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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

  Future<Game?> _fetchGame(String gameId) {
    return gamesRepository.getGame(gameId);
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

    return DefaultTabController(
      length: _statuses.length,
      child: Column(
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      user.email ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const _AppearanceSettings(),
          const SizedBox(height: 8),
          TabBar(
            tabs: [
              Tab(text: 'profile.tab_planned'.tr()),
              Tab(text: 'profile.tab_playing'.tr()),
              Tab(text: 'profile.tab_finished'.tr()),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: _statuses.map((status) {
                return StreamBuilder<List<UserGame>>(
                  stream: _userGamesStream(status),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'common.error_journal'.tr(),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.8),
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
                        child: Text(
                          'common.no_games_category'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: userGames.length,
                      itemBuilder: (context, index) {
                        final ug = userGames[index];

                        return FutureBuilder<Game?>(
                          future: _fetchGame(ug.gameId),
                          builder: (context, gameSnapshot) {
                            if (gameSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: SizedBox(
                                  height: 72,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            }

                            final game = gameSnapshot.data;
                            if (game == null) {
                              return ListTile(
                                title: Text('games.game_deleted'.tr()),
                              );
                            }

                            final statusText = _statusLabel(ug.status);
                            final ratingText = ug.rating != null
                                ? '${'game.rating'.tr()}: ${ug.rating}'
                                : '';
                            final subtitle = [
                              statusText,
                              if (ratingText.isNotEmpty) ratingText,
                            ].join(' • ');

                            return GameCard(
                              game: game,
                              subtitle: subtitle,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        GameDetailScreen(gameId: game.id),
                                  ),
                                );
                              },
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

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final currentLocale = context.locale;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'settings.section_title'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Motyw
              Row(
                children: [
                  Text('settings.theme'.tr()),
                  const SizedBox(width: 16),
                  DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        themeProvider.setThemeMode(mode);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('settings.theme_system'.tr()),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('settings.theme_light'.tr()),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('settings.theme_dark'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Rozmiar czcionki
              Text('settings.font_size'.tr()),
              Slider(
                value: themeProvider.fontScale,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                onChanged: (value) {
                  themeProvider.setFontScale(value);
                },
              ),
              const SizedBox(height: 8),
              // Język
              Row(
                children: [
                  Text('settings.language'.tr()),
                  const SizedBox(width: 16),
                  DropdownButton<Locale>(
                    value: currentLocale,
                    onChanged: (locale) {
                      if (locale != null) {
                        context.setLocale(locale);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: Locale('pl'),
                        child: Text('settings.language_pl'.tr()),
                      ),
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Text('settings.language_en'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
