import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/di/service_locator.dart';
import '../games/for_you_screen.dart';
import '../games/games_list_screen.dart';
import '../games/admin_games_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  static const routeName = '/main';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _adminLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAdminFlag();
  }

  Future<void> _loadAdminFlag() async {
    final user = authRepository.currentUser;
    if (user == null) {
      setState(() {
        _isAdmin = false;
        _adminLoaded = true;
      });
      return;
    }

    final isAdminFlag = await usersRepository.isAdmin(user.uid);
    setState(() {
      _isAdmin = isAdminFlag;
      _adminLoaded = true;
    });
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'nav.for_you'.tr();
      case 1:
        return 'nav.games'.tr();
      case 2:
      default:
        return 'nav.journal'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      ForYouScreen(),
      GamesListScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_currentIndex)),
        actions: [
          if (_adminLoaded && _isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'nav.admin_panel'.tr(),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminGamesScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authRepository.signOut();
              // AuthWrapper sam przełączy na ekran logowania
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.whatshot),
            label: 'nav.for_you'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.videogame_asset),
            label: 'nav.games'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: 'nav.journal'.tr(),
          ),
        ],
      ),
    );
  }
}
