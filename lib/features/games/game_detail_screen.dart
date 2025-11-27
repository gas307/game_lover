import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/di/service_locator.dart';
import '../../core/api/rawg_client.dart';
import '../../core/models/rawg_game.dart';
import '../../core/models/user_game.dart';

class GameDetailScreen extends StatefulWidget {
  final int rawgId;

  const GameDetailScreen({super.key, required this.rawgId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final RawgClient _rawgClient = RawgClient();

  RawgGame? _game;
  bool _loadingGame = true;

  UserGame? _userGame;
  bool _loadingUserGame = true;

  String _status = 'planned';
  int _rating = 0; // 0–5 gwiazdek
  final _noteController = TextEditingController();

  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _loadGame();
    _loadUserGame();
  }

  Future<void> _loadGame() async {
    try {
      final game = await _rawgClient.getGameDetails(widget.rawgId);
      if (!mounted) return;
      setState(() {
        _game = game;
        _loadingGame = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGame = false);
    }
  }

  Future<void> _loadUserGame() async {
    final userId = authRepository.currentUserId;
    if (userId == null) {
      setState(() => _loadingUserGame = false);
      return;
    }

    final ug = await userGamesRepository.getUserGame(
      userId: userId,
      gameId: widget.rawgId,
    );

    if (!mounted) return;

    if (ug != null) {
      _userGame = ug;
      _status = ug.status;
      final savedRating = ug.rating ?? 0;
      _rating = savedRating > 5 ? 5 : (savedRating < 0 ? 0 : savedRating);
      _noteController.text = ug.note ?? '';
    }

    setState(() => _loadingUserGame = false);
  }

  Future<void> _saveUserGame() async {
    final userId = authRepository.currentUserId;
    if (userId == null || _game == null) return;

    final newUserGame = UserGame(
      id: _userGame?.id ?? '',
      userId: userId,
      gameId: widget.rawgId,
      title: _game!.name,
      coverUrl: _game!.backgroundImage ?? '',
      year: _game!.year,
      genre: _game!.genres.isNotEmpty ? _game!.genres.first : null,
      status: _status,
      rating: _rating == 0 ? null : _rating, // 0–5 gwiazdek
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    await userGamesRepository.upsertUserGame(newUserGame);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('game.saved'.tr())),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'playing':
        return 'game.status_playing'.tr();
      case 'finished':
        return 'game.status_finished'.tr();
      case 'planned':
        return 'game.status_planned'.tr();
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingGame) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_game == null) {
      return Scaffold(
        appBar: AppBar(title: Text('game.details_title'.tr())),
        body: Center(child: Text('games.error_loading'.tr())),
      );
    }

    final game = _game!;

    return Scaffold(
      appBar: AppBar(
        title: Text('game.details_title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(game),
            const SizedBox(height: 16),
            _buildExternalRatingCard(game),
            const SizedBox(height: 16),
            _buildDescriptionCard(game),
            const SizedBox(height: 16),
            _buildUserSettingsCard(),
          ],
        ),
      ),
    );
  }

  /// HEADER – obrazek (kwadrat) + info
  Widget _buildHeader(RawgGame game) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(game),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${game.year ?? ''}${game.year != null ? ' • ' : ''}'
                '${game.genres.isNotEmpty ? game.genres.first : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              if (game.platforms.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: game.platforms
                      .map(
                        (p) => Chip(
                          label: Text(p),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// KWADRATOWY obrazek
  Widget _buildCover(RawgGame game) {
    const double size = 140;

    if (game.backgroundImage == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade300,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.videogame_asset, size: 48),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        game.backgroundImage!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade300,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.videogame_asset, size: 48),
          );
        },
      ),
    );
  }

  /// Karta oceny z RAWG – z gwiazdkami
  Widget _buildExternalRatingCard(RawgGame game) {
    final theme = Theme.of(context);

    if (game.rating == null && game.metacritic == null) {
      return const SizedBox.shrink();
    }

    final rawgRating = game.rating ?? 0;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'game.community_rating'.tr(),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (game.rating != null)
              Row(
                children: [
                  _buildStarRow(rawgRating),
                  const SizedBox(width: 8),
                  Text(
                    '${rawgRating.toStringAsFixed(1)} / 5 '
                    '(${game.ratingsCount ?? 0} votes)',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            if (game.metacritic != null) ...[
              const SizedBox(height: 8),
              Text(
                'Metacritic: ${game.metacritic}/100',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Gwiazdki (tylko do odczytu) – rating z RAWG 0–5
  Widget _buildStarRow(double rating) {
    const int maxStars = 5;
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        IconData icon;
        if (index < fullStars) {
          icon = Icons.star_rounded;
        } else if (index == fullStars && hasHalf) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(
          icon,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  /// OPIS – rozwijany „Pokaż więcej / mniej”
  Widget _buildDescriptionCard(RawgGame game) {
    final theme = Theme.of(context);
    final text = game.description?.isNotEmpty == true
        ? game.description!
        : 'game.no_description'.tr();

    final isLong = text.length > 250; // próg, od którego pokazujemy "więcej/mniej"

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'game.description'.tr(),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: theme.textTheme.bodyMedium,
              maxLines: _showFullDescription ? null : 4,
              overflow:
                  _showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (isLong) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showFullDescription = !_showFullDescription;
                    });
                  },
                  child: Text(
                    _showFullDescription
                        ? 'game.read_less'.tr()
                        : 'game.read_more'.tr(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// NOWA, odświeżona karta ustawień użytkownika
  Widget _buildUserSettingsCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _loadingUserGame
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'game.your_settings'.tr(),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // STATUS – Chipy
                  Text(
                    'game.status'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildStatusChip('planned', 'game.status_planned'.tr()),
                      _buildStatusChip('playing', 'game.status_playing'.tr()),
                      _buildStatusChip('finished', 'game.status_finished'.tr()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // TWOJA OCENA – gwiazdki klikalne 0–5
                  Text(
                    'game.rating'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          final filled = starIndex <= _rating;
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: filled ? Colors.amber : Colors.grey,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = starIndex;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      if (_rating > 0)
                        Text(
                          '$_rating / 5',
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ŁADNIEJSZA NOTATKA – "karteczka"
                  Text(
                    'game.note'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.4),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'game.note_hint'.tr(),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lepszy przycisk ZAPISZ – pełna szerokość, dopasowany do stylu
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveUserGame,
                      icon: const Icon(Icons.save),
                      label: Text(
                        'game.save_with_status'
                            .tr(args: [_statusLabel(_status)]),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final theme = Theme.of(context);
    final selected = _status == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _status = value);
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
