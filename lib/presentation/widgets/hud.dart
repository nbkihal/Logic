import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/board_controller.dart';
import '../../application/circuit_controller.dart';
import '../../application/simulation_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/level.dart';

/// Gate count against par, the history controls, and reset.
class Hud extends ConsumerWidget {
  const Hud({super.key, required this.level});

  final Level level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gates = ref.watch(gateCountProvider);
    final controller = ref.read(circuitControllerProvider.notifier);
    // Watching the circuit is what makes the undo/redo buttons re-evaluate
    // after an edit; the stacks themselves live on the controller.
    ref.watch(circuitControllerProvider);

    final overPar = gates > level.par;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12,
            vertical: AppSpacing.x8,
          ),
          decoration: BoxDecoration(
            color: overPar ? AppColors.limestone : AppColors.sulfur,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.obsidian, width: 1.5),
          ),
          child: Semantics(
            label: '$gates gates placed, par is ${level.par}',
            excludeSemantics: true,
            child: Text(
              '$gates / ${level.par}',
              style: AppTypography.textTheme.labelMedium,
            ),
          ),
        ),
        const Spacer(),
        _HudButton(
          icon: Icons.undo,
          tooltip: 'Undo',
          onPressed: controller.canUndo
              ? () {
                  controller.undo();
                  ref.read(boardControllerProvider.notifier)
                      .clearSelection();
                }
              : null,
        ),
        _HudButton(
          icon: Icons.redo,
          tooltip: 'Redo',
          onPressed: controller.canRedo
              ? () {
                  controller.redo();
                  ref.read(boardControllerProvider.notifier)
                      .clearSelection();
                }
              : null,
        ),
        _HudButton(
          icon: Icons.restart_alt,
          tooltip: 'Reset level',
          onPressed: () => _confirmReset(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear the board?'),
        content: const Text(
          'Every gate and wire you placed goes away. The inputs and outputs '
          'stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep building'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear it'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      ref.read(circuitControllerProvider.notifier).reset();
      ref.read(boardControllerProvider.notifier).clearSelection();
    }
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        disabledForegroundColor: AppColors.obsidianFaint,
      ),
    );
  }
}
