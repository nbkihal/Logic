import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/board_controller.dart';
import '../../application/circuit_controller.dart';
import '../../application/level_scope.dart';
import '../../application/simulation_provider.dart';
import '../../application/sound_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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
    // Under par the pill is Sulfur, over it it is a plain card — so the ink
    // has to follow the fill, not the page.
    final pillInk =
        overPar ? context.colors.obsidian : context.colors.onSulfur;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12,
            vertical: AppSpacing.x8,
          ),
          decoration: BoxDecoration(
            color: overPar ? context.colors.limestone : context.colors.sulfur,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: context.colors.obsidian, width: 1.5),
          ),
          child: Semantics(
            label: '$gates gates placed, par is ${level.par}',
            excludeSemantics: true,
            child: Text(
              '$gates / ${level.par}',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: pillInk),
            ),
          ),
        ),
        const Spacer(),
        const HintButton(),
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

/// Asks for the next rung of help, and says what it just gave away.
///
/// The message is a snack rather than a panel because a hint is a nudge: it
/// should be readable in a second and then get out of the way of the board.
class HintButton extends ConsumerWidget {
  const HintButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(levelProvider);
    final given = ref.watch(hintProvider);
    if (level == null) return const SizedBox.shrink();

    final exhausted = given == HintLevel.keystone ||
        (given == HintLevel.narrowed && level.keystoneGate == null);

    return _HudButton(
      icon: given == HintLevel.none
          ? Icons.lightbulb_outline
          : Icons.lightbulb,
      tooltip: 'Hint',
      onPressed: exhausted
          ? null
          : () {
              ref.read(soundProvider).play(Sfx.tap);
              ref.read(hintProvider.notifier).next(
                    tableAlreadyVisible: level.showTargetTable,
                  );
              final message = _messageFor(
                ref.read(hintProvider),
                level,
              );
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(message),
                    duration: const Duration(seconds: 6),
                  ),
                );
            },
    );
  }

  String _messageFor(HintLevel given, Level level) => switch (given) {
        HintLevel.none => '',
        HintLevel.table => 'Table revealed. Read it row by row.',
        HintLevel.narrowed => _narrowedMessage(level),
        HintLevel.keystone => _keystoneMessage(level),
      };

  String _narrowedMessage(Level level) {
    final unused = level.unusedGates;
    if (unused.isEmpty) {
      return 'Every gate on offer earns its place in a par solution.';
    }
    final names = unused.map((g) => g.label).toList()..sort();
    return 'A ${level.par}-gate solution needs none of: '
        '${names.join(', ')}. They are crossed off below.';
  }

  String _keystoneMessage(Level level) {
    final gate = level.keystoneGate;
    if (gate == null) return 'No further hint for this one.';
    final count = level.solutionGates[gate] ?? 1;
    final many = count > 1 ? ' — $count of them' : '';
    return 'Start with ${gate.label}$many. It is ringed in the palette.';
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
        disabledForegroundColor: context.colors.obsidianFaint,
      ),
    );
  }
}
