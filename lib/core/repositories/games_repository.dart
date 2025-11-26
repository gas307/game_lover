import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';

class GamesRepository {
  final FirebaseFirestore _db;
  GamesRepository(this._db);

  CollectionReference get _gamesRef => _db.collection('games');

  Stream<List<Game>> watchAllGames() {
    return _gamesRef
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Game.fromDoc).toList());
  }

  Stream<Game?> watchGame(String id) {
    return _gamesRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Game.fromDoc(doc);
    });
  }

  Future<Game?> getGame(String id) async {
    final doc = await _gamesRef.doc(id).get();
    if (!doc.exists) return null;
    return Game.fromDoc(doc);
  }

  Future<void> addGame(Game game) async {
    await _gamesRef.add(game.toMap());
  }

  Future<void> updateGame(Game game) async {
    await _gamesRef.doc(game.id).update(game.toMap());
  }

  /// SEED – jednorazowe wrzucenie przykładowych gier
  Future<void> seedPopularGames() async {
    final games = [
      {
        'title': 'Baldur\'s Gate 3',
        'year': 2023,
        'genre': 'RPG',
        'description':
            'Izometryczne RPG osadzone w świecie Dungeons & Dragons.',
        'coverUrl': '',
        'platforms': ['PC', 'PS5', 'Xbox Series'],
      },
      {
        'title': 'Starfield',
        'year': 2023,
        'genre': 'RPG',
        'description':
            'Kosmiczne RPG od twórców serii The Elder Scrolls i Fallout.',
        'coverUrl': '',
        'platforms': ['PC', 'Xbox Series'],
      },
      {
        'title': 'Lies of P',
        'year': 2023,
        'genre': 'Action RPG',
        'description':
            'Soulslike inspirowany historią Pinokia w mrocznym mieście Krat.',
        'coverUrl': '',
        'platforms': ['PC', 'PS4', 'PS5', 'Xbox One', 'Xbox Series'],
      },
      {
        'title': 'Alan Wake 2',
        'year': 2023,
        'genre': 'Horror',
        'description':
            'Psychologiczny survival horror z elementami thrillera.',
        'coverUrl': '',
        'platforms': ['PC', 'PS5', 'Xbox Series'],
      },
      {
        'title': 'Hi-Fi RUSH',
        'year': 2023,
        'genre': 'Rhythm Action',
        'description':
            'Kolorowa gra akcji, w której wszystko dzieje się w rytm muzyki.',
        'coverUrl': '',
        'platforms': ['PC', 'Xbox Series'],
      },
      {
        'title': 'Remnant II',
        'year': 2023,
        'genre': 'Action',
        'description':
            'Kooperacyjna strzelanka akcji z elementami RPG i soulslike.',
        'coverUrl': '',
        'platforms': ['PC', 'PS5', 'Xbox Series'],
      },
      {
        'title': 'Diablo IV',
        'year': 2023,
        'genre': 'Action RPG',
        'description':
            'Kontynuacja kultowej serii hack\'n\'slash w mrocznym świecie Sanktuarium.',
        'coverUrl': '',
        'platforms': ['PC', 'PS4', 'PS5', 'Xbox One', 'Xbox Series'],
      },
      {
        'title': 'Resident Evil 4 Remake',
        'year': 2023,
        'genre': 'Horror',
        'description':
            'Odświeżona wersja klasycznego survival horroru od Capcom.',
        'coverUrl': '',
        'platforms': ['PC', 'PS4', 'PS5', 'Xbox Series'],
      },
      {
        'title': 'Dead Space Remake',
        'year': 2023,
        'genre': 'Horror',
        'description':
            'Remake kultowego sci-fi survival horroru na statku Ishimura.',
        'coverUrl': '',
        'platforms': ['PC', 'PS5', 'Xbox Series'],
      },
      {
        'title': 'Street Fighter 6',
        'year': 2023,
        'genre': 'Fighting',
        'description':
            'Bijatyka 1v1 z rozbudowanym trybem single i online.',
        'coverUrl': '',
        'platforms': ['PC', 'PS4', 'PS5', 'Xbox One', 'Xbox Series'],
      },
      {
        'title': 'Armored Core VI: Fires of Rubicon',
        'year': 2023,
        'genre': 'Action',
        'description':
            'Szybka gra akcji z mechami od FromSoftware.',
        'coverUrl': '',
        'platforms': ['PC', 'PS4', 'PS5', 'Xbox One', 'Xbox Series'],
      },
      {
        'title': 'Assassin\'s Creed Mirage',
        'year': 2023,
        'genre': 'Action',
        'description':
            'Powrót do skradankowych korzeni serii Assassin\'s Creed.',
        'coverUrl': '',
        'platforms': ['PC', 'PS5', 'PS4', 'Xbox One', 'Xbox Series'],
      },
      {
        'title': 'Forza Motorsport',
        'year': 2023,
        'genre': 'Racing',
        'description':
            'Symulator wyścigów samochodowych od Turn 10 Studios.',
        'coverUrl': '',
        'platforms': ['PC', 'Xbox Series'],
      },
      {
        'title': 'The Callisto Protocol',
        'year': 2022,
        'genre': 'Horror',
        'description':
            'Kosmiczny survival horror od twórców Dead Space.',
        'coverUrl': '',
        'platforms': ['PC', 'PS5', 'PS4', 'Xbox One', 'Xbox Series'],
      },
      {
        'title': 'Sifu',
        'year': 2022,
        'genre': 'Action',
        'description':
            'Bijatyka kung-fu z unikalnym systemem starzenia się bohatera.',
        'coverUrl': '',
        'platforms': ['PC', 'PS4', 'PS5', 'Switch'],
      },
      {
        'title': 'Stray',
        'year': 2022,
        'genre': 'Adventure',
        'description':
            'Przygodówka, w której sterujesz kotem w cyberpunkowym mieście.',
        'coverUrl': '',
        'platforms': ['PC', 'PS4', 'PS5', 'Xbox One', 'Xbox Series'],
      },
      {
        'title': 'Cult of the Lamb',
        'year': 2022,
        'genre': 'Roguelike',
        'description':
            'Mroczna, urocza gra o zakładaniu kultu w lesie.',
        'coverUrl': '',
        'platforms': ['PC', 'PS4', 'PS5', 'Xbox', 'Switch'],
      },
      {
        'title': 'Vampire Survivors',
        'year': 2022,
        'genre': 'Roguelike',
        'description':
            'Prosta gra survivalowa z ogromną ilością przeciwników.',
        'coverUrl': '',
        'platforms': ['PC', 'Xbox', 'Mobile', 'Switch'],
      },
      {
        'title': 'Hades',
        'year': 2020,
        'genre': 'Roguelike',
        'description':
            'Dynamiczny roguelike w świecie greckiej mitologii.',
        'coverUrl': '',
        'platforms': ['PC', 'Switch', 'PS4', 'PS5', 'Xbox'],
      },
      {
        'title': 'Ghost of Tsushima',
        'year': 2020,
        'genre': 'Action',
        'description':
            'Samurajska gra akcji w otwartym świecie feudalnej Japonii.',
        'coverUrl': '',
        'platforms': ['PS4', 'PS5'],
      },
    ];

    for (final game in games) {
      await _gamesRef.add({
        ...game,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
