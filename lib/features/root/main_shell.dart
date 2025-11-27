import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/di/service_locator.dart';
import '../games/for_you_screen.dart';
import '../games/games_list_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  static const routeName = '/main';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

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
        title: Text(
          _titleForIndex(_currentIndex),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsBold.gearSix),
            tooltip: 'nav.settings'.tr(),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsBold.signOut),
            onPressed: () async {
              await authRepository.signOut();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(PhosphorIconsBold.fire),
            label: 'nav.for_you'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(PhosphorIconsBold.gameController),
            label: 'nav.games'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(PhosphorIconsBold.bookOpenText),
            label: 'nav.journal'.tr(),
          ),
        ],
      ),
    );
  }
}
