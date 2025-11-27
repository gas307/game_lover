import 'dart:convert';
import 'package:http/http.dart' as http;

import 'rawg_config.dart';
import '../models/rawg_game.dart';

class RawgClient {
  final http.Client _client;

  RawgClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<RawgGame>> fetchPopularGames({int page = 1}) async {
    final uri = Uri.parse(
      '$rawgBaseUrl/games?key=$rawgApiKey&ordering=-added&page_size=80&page=$page',
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('RAWG error: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => RawgGame.fromListJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RawgGame>> searchGames(String query, {int page = 1}) async {
    final uri = Uri.parse(
      '$rawgBaseUrl/games?key=$rawgApiKey&search=$query&page_size=80&page=$page',
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('RAWG error: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => RawgGame.fromListJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RawgGame?> getGameDetails(int id) async {
    final uri = Uri.parse('$rawgBaseUrl/games/$id?key=$rawgApiKey');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return RawgGame.fromDetailJson(data);
  }
}
