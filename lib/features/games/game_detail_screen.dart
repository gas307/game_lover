import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/game.dart';
import '../../core/models/user_game.dart';

class GameDetailScreen extends StatefulWidget {
  final String gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  UserGame? _userGame;
  bool _loadingUserGame = true;
  String _status = 'planned';
  double _rating = 0;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserGame();
  }

  Future<void> _loadUserGame() async {
    final userId = authRepository.currentUserId;
    if (userId == null) {
      setState(() => _loadingUserGame = false);
      return;
    }

    final ug = await userGamesRepository.getUserGame(
      userId: userId,
      gameId: widget.gameId,
    );

    if (ug != null) {
      _userGame = ug;
      _status = ug.status;
      _rating = (ug.rating ?? 0).toDouble();
      _noteController.text = ug.note ?? '';
    }

    setState(() => _loadingUserGame = false);
  }

  Future<void> _saveUserGame() async {
    final userId = authRepository.currentUserId;
    if (userId == null) return;

    final newUserGame = UserGame(
      id: _userGame?.id ?? '',
      userId: userId,
      gameId: widget.gameId,
      status: _status,
      rating: _rating == 0 ? null : _rating.toInt(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    await userGamesRepository.upsertUserGame(newUserGame);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('common.diary_updated'.tr())),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'playing':
        return 'Gram';
      case 'finished':
        return 'Ukończona';
      case 'planned':
      default:
        return 'Chcę zagrać';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('game.details_title'.tr()),
      ),
      body: StreamBuilder<Game?>(
        stream: gamesRepository.watchGame(widget.gameId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('game.error_loading'.tr()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final game = snapshot.data;
            if (game == null) {
              return Center(child: Text('game.not_exists'.tr()));
            }          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(game),
                const SizedBox(height: 16),
                _buildDescriptionCard(game),
                const SizedBox(height: 16),
                _buildUserSettingsCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Game game) {
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
                game.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${game.year} • ${game.genre}',
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

  Widget _buildCover(Game game) {
    if (game.coverUrl.isEmpty) {
      return Container(
        width: 120,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade300,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.videogame_asset, size: 48),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        game.coverUrl,
        width: 120,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade300,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.videogame_asset, size: 48),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionCard(Game game) {
    final theme = Theme.of(context);
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
              game.description.isNotEmpty
                  ? game.description
                  : 'game.no_description'.tr(),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSettingsCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
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
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'game.status'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'planned',
                        child: Text('game.status_planned'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'playing',
                        child: Text('game.status_playing'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'finished',
                        child: Text('game.status_finished'.tr()),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _status = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('game.rating'.tr() + ': '),
                      Expanded(
                        child: Slider(
                          value: _rating,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _rating.toStringAsFixed(0),
                          onChanged: (value) {
                            setState(() => _rating = value);
                          },
                        ),
                      ),
                      if (_rating > 0)
                        Text(
                          _rating.toStringAsFixed(0),
                          style: theme.textTheme.titleMedium,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'game.note'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _saveUserGame,
                      icon: const Icon(Icons.save),
                      label: Text('game.save_with_status'.tr(args: [_statusLabel(_status)])),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
