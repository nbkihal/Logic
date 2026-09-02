import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/caldera_scaffold.dart';

/// Phase 0 stub. The canvas, palette, HUD and tester arrive in Phases 2-4.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.levelId});

  final int levelId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CalderaScaffold(
      onBack: () => context.go(AppRoutes.levelSelect),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.x24),
          Text('LEVEL $levelId', style: text.headlineLarge),
          const SizedBox(height: AppSpacing.x16),
          Text('The board arrives in Phase 2.', style: text.bodyLarge),
        ],
      ),
    );
  }
}
