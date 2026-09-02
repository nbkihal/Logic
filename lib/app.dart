import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Owns the router and the theme; nothing else.
class LogicCircuitBuilderApp extends StatefulWidget {
  const LogicCircuitBuilderApp({super.key, this.router});

  /// Injectable so tests can start at an arbitrary route.
  final GoRouter? router;

  @override
  State<LogicCircuitBuilderApp> createState() => _LogicCircuitBuilderAppState();
}

class _LogicCircuitBuilderAppState extends State<LogicCircuitBuilderApp> {
  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Logic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
