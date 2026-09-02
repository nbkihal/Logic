import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/levels/level_repository.dart';
import '../../../domain/models/level.dart';
import '../../canvas/circuit_canvas.dart';
import '../../widgets/caldera_scaffold.dart';

/// The core screen. Phase 2 renders a hard-coded board; the palette, HUD and
/// truth-table panel arrive in Phases 3 and 4.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.levelId});

  static const _repository = LevelRepository();

  final int levelId;

  @override
  Widget build(BuildContext context) {
    final level = _repository.byId(levelId);
    final text = Theme.of(context).textTheme;

    return CalderaScaffold(
      onBack: () => context.go(AppRoutes.levelSelect),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x16),
          _Header(level: level, levelId: levelId),
          const SizedBox(height: AppSpacing.x8),
          Text(
            'Phase 2 preview — pan and zoom work, editing lands in Phase 3.',
            style: text.bodySmall?.copyWith(color: AppColors.obsidianMuted),
          ),
          const SizedBox(height: AppSpacing.x12),
          Expanded(
            child: CircuitCanvas(
              inputNames: level?.target.inputNames ?? const [],
              outputNames: level?.target.outputNames ?? const [],
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.level, required this.levelId});

  final Level? level;
  final int levelId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level?.name.toUpperCase() ?? 'LEVEL $levelId',
                style: text.headlineSmall,
              ),
              if (level != null)
                Text(
                  level!.blurb,
                  style: text.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (level != null)
          Chip(
            label: Text('PAR ${level!.par}'),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
