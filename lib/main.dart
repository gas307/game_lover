import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/auth_wrapper.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/games/games_list_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/games/admin_games_screen.dart';
import 'features/root/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('pl'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('pl'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const GameDiaryApp(),
      ),
    ),
  );
}

class GameDiaryApp extends StatelessWidget {
  const GameDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final baseLight = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    final baseDark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'app_title'.tr(),
      debugShowCheckedModeBanner: false,
      theme: baseLight,
      darkTheme: baseDark,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const AuthWrapper(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        GamesListScreen.routeName: (_) => const GamesListScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        AdminGamesScreen.routeName: (_) => const AdminGamesScreen(),
        MainShell.routeName: (_) => const MainShell(),
      },
      // TU skalujemy czcionkę globalnie zamiast grzebać w TextStyle
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaleFactor: themeProvider.fontScale,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
