import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/api/rawg_client.dart';
import '../../core/models/rawg_game.dart';
import 'game_detail_screen.dart';

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});
  static const routeName = '/games';

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  final RawgClient _rawgClient = RawgClient();
  final TextEditingController _searchController = TextEditingController();

  List<RawgGame> _games = [];
  bool _isLoading = false;
  String? _error;

  String _search = '';
  int? _selectedYear;
  String? _selectedGenre;
  String? _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _loadPopular();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopular() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final games = await _rawgClient.fetchPopularGames();
      setState(() => _games = games);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchGames(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await _loadPopular();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final games = await _rawgClient.searchGames(trimmed);
      setState(() => _games = games);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = _games
        .map((g) => g.year)
        .where((y) => y != null)
        .cast<int>()
        .toSet()
        .toList()
      ..sort();
    final genres = _games
        .expand((g) => g.genres)
        .toSet()
        .toList()
      ..sort();
    final platforms = _games
        .expand((g) => g.platforms)
        .toSet()
        .toList()
      ..sort();

    final filteredGames = _games.where((game) {
      final matchesSearch = _search.isEmpty ||
          game.name.toLowerCase().contains(_search);

      final matchesYear =
          _selectedYear == null || game.year == _selectedYear;

      final matchesGenre = _selectedGenre == null ||
          game.genres.contains(_selectedGenre);

      final matchesPlatform = _selectedPlatform == null ||
          game.platforms.contains(_selectedPlatform);

      return matchesSearch && matchesYear && matchesGenre && matchesPlatform;
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildSearchBar(context),
        const SizedBox(height: 8),
        _buildFiltersCard(context, years, genres, platforms),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'games.error_loading'.tr(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : filteredGames.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'games.no_games'.tr(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: filteredGames.length,
                          itemBuilder: (context, index) {
                            final game = filteredGames[index];
                            return _GameListCard(game: game)
                                .animate()
                                .fadeIn(duration: 180.ms, delay: (index * 20).ms)
                                .slide(
                                  begin: const Offset(0, 0.05),
                                  curve: Curves.easeOut,
                                );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(24),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'games.search_title'.tr(),
            prefixIcon: const Icon(PhosphorIconsBold.magnifyingGlass),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _search = '';
                      });
                      _loadPopular();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) {
            setState(() => _search = value.toLowerCase());
          },
          onSubmitted: (value) => _searchGames(value),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildFiltersCard(
    BuildContext context,
    List<int> years,
    List<String> genres,
    List<String> platforms,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIconsBold.slidersHorizontal,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'games.filters_title'.tr(), // np. "Filtry"
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _YearFilterDropdown(
                      years: years,
                      selectedYear: _selectedYear,
                      onChanged: (value) {
                        setState(() => _selectedYear = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SimpleFilterDropdown(
                      label: 'games.filter_genre'.tr(),
                      allLabel: 'games.all_genres'.tr(),
                      values: genres,
                      selected: _selectedGenre,
                      onChanged: (value) {
                        setState(() => _selectedGenre = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SimpleFilterDropdown(
                      label: 'games.filter_platform'.tr(),
                      allLabel: 'games.all_platforms'.tr(),
                      values: platforms,
                      selected: _selectedPlatform,
                      onChanged: (value) {
                        setState(() => _selectedPlatform = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearFilterDropdown extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int?> onChanged;

  const _YearFilterDropdown({
    required this.years,
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: selectedYear,
      decoration: InputDecoration(
        labelText: 'games.filter_year'.tr(),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      isDense: true,
      onChanged: onChanged,
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text('games.all_years'.tr()),
        ),
        ...years.map(
          (y) => DropdownMenuItem<int?>(
            value: y,
            child: Text(y.toString()),
          ),
        ),
      ],
    );
  }
}

class _SimpleFilterDropdown extends StatelessWidget {
  final String label;
  final String allLabel;
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _SimpleFilterDropdown({
    required this.label,
    required this.allLabel,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      isDense: true,
      onChanged: onChanged,
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(allLabel),
        ),
        ...values.map(
          (v) => DropdownMenuItem<String?>(
            value: v,
            child: Text(v),
          ),
        ),
      ],
    );
  }
}

/// Pojedyncza karta gry na liście
class _GameListCard extends StatelessWidget {
  final RawgGame game;

  const _GameListCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameDetailScreen(rawgId: game.id),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:
                    theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
                  child: _buildInfo(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (game.backgroundImage == null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          bottomLeft: Radius.circular(18),
        ),
        child: Container(
          width: 90,
          height: 110,
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(
            PhosphorIconsBold.gameController,
            size: 32,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        bottomLeft: Radius.circular(18),
      ),
      child: Image.network(
        game.backgroundImage!,
        width: 90,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 90,
            height: 110,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(
              PhosphorIconsBold.gameController,
              size: 32,
            ),
          );
        },
      ),
    );
  }

    Widget _buildInfo(BuildContext context) {
      final theme = Theme.of(context);

      final yearGenre = [
        if (game.year != null) game.year.toString(),
        if (game.genres.isNotEmpty) game.genres.first,
      ].join(' • ');

      final platforms = game.platforms.join(', ');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            game.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (yearGenre.isNotEmpty)
            Text(
              yearGenre,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          if (platforms.isNotEmpty)
            Text(
              platforms,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8), // zamiast Spacer()
          Row(
            children: [
              if (game.rating != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        game.rating!.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Icon(
                PhosphorIconsBold.caretRight,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ],
      );
    }

}
