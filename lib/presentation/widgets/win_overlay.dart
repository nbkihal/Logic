import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/level.dart';

/// Shown once a level is solved: stars, gate count against par, and where to
/// go next.
class WinOverlay extends StatelessWidget {
  const WinOverlay({
    super.key,
    required this.level,
    required this.stars,
    required this.gateCount,
    required this.onRetry,
    required this.onNext,
    required this.onLevels,
    this.hasNext = true,
  });

  final Level level;
  final int stars;
  final int gateCount;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onLevels;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'Level solved with $stars of 3 stars, using $gateCount gates. '
          'Par is ${level.par}.',
      child: ColoredBox(
        color: AppColors.obsidian.withValues(alpha: 0.55),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.x24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(AppSpacing.x32),
              decoration: BoxDecoration(
                color: AppColors.limestone,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SOLVED', style: text.headlineLarge),
                  const SizedBox(height: AppSpacing.x8),
                  Text(level.name, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.x24),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.x8),
                          child: Icon(
                            i < stars ? Icons.star : Icons.star_border,
                            size: 40,
                            color: i < stars
                                ? AppColors.ember
                                : AppColors.obsidianFaint,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x16),
                  Text(
                    gateCount <= level.par
                        ? '$gateCount gates — par is ${level.par}. '
                            'Nothing wasted.'
                        : '$gateCount gates. Par is ${level.par} — there is a '
                            'tighter circuit in there.',
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.x32),
                  Wrap(
                    spacing: AppSpacing.x12,
                    runSpacing: AppSpacing.x12,
                    children: [
                      if (hasNext)
                        FilledButton(
                          onPressed: onNext,
                          child: const Text('Next level'),
                        ),
                      if (stars < 3)
                        OutlinedButton(
                          onPressed: onRetry,
                          child: const Text('Try for 3 stars'),
                        ),
                      TextButton(
                        onPressed: onLevels,
                        child: const Text('All levels'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three-star row, reused on level cards.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 16});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars of 3 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < stars ? Icons.star : Icons.star_border,
              size: size,
              color: i < stars ? AppColors.ember : AppColors.obsidianFaint,
            ),
        ],
      ),
    );
  }
}

/// Small caps label used above values on cards.
TextStyle captionStyle() =>
    AppTypography.textTheme.labelSmall!.copyWith(letterSpacing: 1.5);
