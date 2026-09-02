import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/caldera_scaffold.dart';

/// Phase 0 stub. Phase 6 fills this with real level cards, stars and locks.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CalderaScaffold(
      onBack: () => context.go(AppRoutes.home),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.x24),
          Text('LEVELS', style: text.headlineLarge),
          const SizedBox(height: AppSpacing.x16),
          Text('Level cards land in Phase 6.', style: text.bodyLarge),
          const SizedBox(height: AppSpacing.x24),
          FilledButton(
            onPressed: () => context.go(AppRoutes.game(1)),
            child: const Text('Open level 1'),
          ),
        ],
      ),
    );
  }
}
