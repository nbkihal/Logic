import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'application/progress_controller.dart';
import 'core/constants/animation_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Owns the router and the theme; nothing else.
class LogicCircuitBuilderApp extends ConsumerStatefulWidget {
  const LogicCircuitBuilderApp({super.key, this.router});

  /// Injectable so tests can start at an arbitrary route.
  final GoRouter? router;

  @override
  ConsumerState<LogicCircuitBuilderApp> createState() =>
      _LogicCircuitBuilderAppState();
}

class _LogicCircuitBuilderAppState
    extends ConsumerState<LogicCircuitBuilderApp> {
  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final palette = AppPalette.byId(settings.themeId);

    return MaterialApp.router(
      title: 'Logic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(palette),
      // `AppPalette.lerp` makes a theme change a sweep across every surface
      // at once, which is the whole reason to offer more than one.
      themeAnimationDuration: settings.reducedMotion
          ? Duration.zero
          : AnimationConstants.themeSweep,
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: _router,
    );
  }
}
