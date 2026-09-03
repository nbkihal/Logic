import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../application/progress_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/levels/level_repository.dart';
import '../../../data/persistence/progress_model.dart';
import '../../../domain/models/level.dart';
import '../../widgets/caldera_scaffold.dart';
import '../../widgets/win_overlay.dart';

/// The arc, in order, with each level's lock state, stars and best.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = const LevelRepository().all;
    final progress = ref.watch(progressProvider);
    final text = Theme.of(context).textTheme;

    return CalderaScaffold(
      onBack: () => context.go(AppRoutes.home),
      actions: [
        Text('${progress.totalStars} / ${levels.length * 3} ★',
            style: text.labelMedium),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          final chapters = const LevelRepository().chapters;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.x16,
                    bottom: AppSpacing.x16,
                  ),
                  child: Text('LEVELS', style: text.headlineLarge),
                ),
              ),
              // One header + grid per chapter. Sixty-odd cards in a single
              // run reads as a wall; the chapter names are the map.
              for (final chapter in chapters) ...[
                SliverToBoxAdapter(
                  child: ChapterHeading(
                    chapter: chapter,
                    progress: progress,
                  ),
                ),
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.x12,
                    crossAxisSpacing: AppSpacing.x12,
                    // Tall enough for a three-line blurb at a large system
                    // font scale; the later chapters have more to say than
                    // "flip the signal".
                    mainAxisExtent: 160,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: chapter.levels.length,
                    (context, index) {
                      final level = chapter.levels[index];
                      return LevelCard(
                        level: level,
                        progress: progress.forLevel(level.id),
                        unlocked: progress.isUnlocked(level.id),
                        onTap: () => context.go(AppRoutes.game(level.id)),
                      );
                    },
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.x24),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A chapter's name, with how far the player has got inside it.
class ChapterHeading extends StatelessWidget {
  const ChapterHeading({
    super.key,
    required this.chapter,
    required this.progress,
  });

  final Chapter chapter;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final solved =
        chapter.levels.where((l) => progress.forLevel(l.id).solved).length;

    return Semantics(
      header: true,
      label: '${chapter.name}. $solved of ${chapter.levels.length} solved.',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.x32,
          bottom: AppSpacing.x12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chapter.name.toUpperCase(),
                style: text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.x8),
            Text('$solved / ${chapter.levels.length}', style: captionStyle()),
          ],
        ),
      ),
    );
  }
}

/// One level's card: name, teaching hook, stars, best gate count, or a lock.
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.progress,
    required this.unlocked,
    required this.onTap,
  });

  final Level level;
  final LevelProgress progress;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      enabled: unlocked,
      label: unlocked
          ? 'Level ${level.id}, ${level.name}. '
              '${progress.stars} of 3 stars.'
          : 'Level ${level.id}, ${level.name}. Locked — solve level '
              '${level.id - 1} first.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: unlocked ? onTap : null,
        child: Opacity(
          opacity: unlocked ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.x20),
            decoration: BoxDecoration(
              color: progress.solved ? context.colors.sulfur : context.colors.limestone,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: unlocked ? context.colors.obsidian : context.colors.hairline,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${level.id}'.padLeft(2, '0'),
                        style: text.headlineSmall),
                    const SizedBox(width: AppSpacing.x8),
                    Expanded(
                      child: Text(
                        level.name.toUpperCase(),
                        style: text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!unlocked)
                      const Icon(Icons.lock_outline, size: 18)
                    else
                      StarRow(stars: progress.stars),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                Expanded(
                  child: Text(
                    level.blurb,
                    style: text.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text('PAR ${level.par}', style: captionStyle()),
                    const Spacer(),
                    if (progress.bestGateCount != null)
                      Text(
                        'BEST ${progress.bestGateCount}',
                        style: captionStyle(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
