import 'package:go_router/go_router.dart';

import 'presentation/screens/game/game_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/how_to_play/how_to_play_screen.dart';
import 'presentation/screens/level_select/level_select_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

/// Route paths, kept in one place so navigation calls never hard-code strings.
abstract final class AppRoutes {
  static const home = '/';
  static const levelSelect = '/levels';
  static const settings = '/settings';
  static const howToPlay = '/how-to-play';

  /// Game takes the level id as a path parameter.
  static const gamePattern = '/levels/:levelId';
  static String game(int levelId) => '/levels/$levelId';
}

GoRouter buildRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.levelSelect,
        builder: (context, state) => const LevelSelectScreen(),
        routes: [
          GoRoute(
            path: ':levelId',
            builder: (context, state) => GameScreen(
              levelId: int.tryParse(state.pathParameters['levelId'] ?? '') ?? 1,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.howToPlay,
        builder: (context, state) => const HowToPlayScreen(),
      ),
    ],
  );
}
