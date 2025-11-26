import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/game.dart';
import 'game_detail_screen.dart';
import 'widgets/game_card.dart';

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});
  static const routeName = '/games';

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  String _search = '';
  int? _selectedYear;
  String? _selectedGenre;
  String? _selectedPlatform;

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

        final allGames = snapshot.data!;

        // Zbuduj listy opcji do filtrów na podstawie danych z bazy
        final years = allGames
            .map((g) => g.year)
            .where((y) => y > 0)
            .toSet()
            .toList()
          ..sort();

        final genres = allGames
            .map((g) => g.genre)
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        final platforms = allGames
            .expand((g) => g.platforms)
            .where((p) => p.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        // Zastosuj wyszukiwanie + filtry
        final games = allGames.where((game) {
          final matchesSearch = _search.isEmpty ||
              game.title.toLowerCase().contains(_search);

          final matchesYear =
              _selectedYear == null || game.year == _selectedYear;

          final matchesGenre =
              _selectedGenre == null || game.genre == _selectedGenre;

          final matchesPlatform = _selectedPlatform == null ||
              game.platforms.contains(_selectedPlatform);

          return matchesSearch && matchesYear && matchesGenre && matchesPlatform;
        }).toList();

        return Column(
          children: [
            // Pasek wyszukiwania
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'games.search_title'.tr(),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _search = value.toLowerCase());
                },
              ),
            ),

            // Pasek filtrów
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Rok
                        _YearFilterDropdown(
                          years: years,
                          selectedYear: _selectedYear,
                          onChanged: (value) {
                            setState(() => _selectedYear = value);
                          },
                        ),
                        const SizedBox(width: 8),
                        // Gatunek
                        _SimpleFilterDropdown(
                          label: 'games.filter_genre'.tr(),
                          allLabel: 'games.all_genres'.tr(),
                          values: genres,
                          selected: _selectedGenre,
                          onChanged: (value) {
                            setState(() => _selectedGenre = value);
                          },
                        ),
                        const SizedBox(width: 8),
                        // Platforma
                        _SimpleFilterDropdown(
                          label: 'games.filter_platform'.tr(),
                          allLabel: 'games.all_platforms'.tr(),
                          values: platforms,
                          selected: _selectedPlatform,
                          onChanged: (value) {
                            setState(() => _selectedPlatform = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Lista gier
            Expanded(
              child: games.isEmpty
                  ? Center(child: Text('games.no_games'.tr()))
                  : ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return GameCard(
                          game: game,
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
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Dropdown do wyboru roku (int + opcja "All")
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
    return DropdownButton<int?>(
      value: selectedYear,
      hint: Text('games.filter_year'.tr()),
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

/// Uniwersalny dropdown dla stringów (gatunek / platforma)
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
    return DropdownButton<String?>(
      value: selected,
      hint: Text(label),
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
