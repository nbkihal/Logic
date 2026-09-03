import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../application/progress_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/levels/level_repository.dart';

/// Title screen. Continue where you left off, or start from the beginning.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(progressProvider);
    final levelCount = const LevelRepository().count;
    final resume = progress.highestUnlocked(levelCount);
    final started = progress.totalStars > 0;
    final wide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: context.colors.pumice,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.x24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOGIC',
                    style: (wide ? text.displayLarge : text.displaySmall)
                        ?.copyWith(color: context.colors.ember),
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  Text(
                    'CIRCUIT BUILDER',
                    style: text.labelMedium?.copyWith(letterSpacing: 3),
                  ),
                  const SizedBox(height: AppSpacing.x24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      'Wire gates together until the lamps match the table. '
                      'Sixty-three stages, from a single NOT gate to a '
                      'two-bit multiplier.',
                      style: text.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x32),
                  Wrap(
                    spacing: AppSpacing.x12,
                    runSpacing: AppSpacing.x12,
                    children: [
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.game(resume)),
                        child: Text(started ? 'Continue' : 'Play'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go(AppRoutes.levelSelect),
                        child: const Text('Levels'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go(AppRoutes.howToPlay),
                        child: const Text('How to play'),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.settings),
                        child: const Text('Settings'),
                      ),
                    ],
                  ),
                  if (started) ...[
                    const SizedBox(height: AppSpacing.x32),
                    Text(
                      '${progress.totalStars} of ${levelCount * 3} stars — '
                      'up to level $resume.',
                      style: text.bodySmall
                          ?.copyWith(color: context.colors.obsidianMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
