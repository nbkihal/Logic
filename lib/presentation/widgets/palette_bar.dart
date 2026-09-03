import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/board_controller.dart';
import '../../application/circuit_controller.dart';
import '../../application/simulation_provider.dart';
import '../../application/sound_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/gate_type.dart';

/// The level's available components, plus the delete affordance.
///
/// Tap a gate to arm it, then tap the board to drop it — a two-tap placement
/// rather than a drag, so it works the same with a finger, a mouse, or a
/// screen reader.
class PaletteBar extends ConsumerWidget {
  const PaletteBar({super.key, required this.palette});

  final Set<GateType> palette;

  /// A stable, teaching-order layout so a gate does not move between levels.
  static const _order = [
    GateType.not,
    GateType.and,
    GateType.or,
    GateType.nand,
    GateType.nor,
    GateType.xor,
    GateType.xnor,
    GateType.buffer,
    GateType.constant,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardControllerProvider);
    final available = _order.where(palette.contains).toList();
    final ruledOut = ref.watch(ruledOutGatesProvider);
    final suggested = ref.watch(suggestedGateProvider);

    return Semantics(
      container: true,
      label: 'Component palette',
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x4,
                  vertical: AppSpacing.x8,
                ),
                itemCount: available.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.x8),
                itemBuilder: (context, index) {
                  final type = available[index];
                  return _PaletteChip(
                    type: type,
                    armed: board.armed == type,
                    ruledOut: ruledOut.contains(type),
                    suggested: suggested == type,
                    onTap: () {
                      ref.read(soundProvider).play(Sfx.tap);
                      ref.read(boardControllerProvider.notifier).arm(type);
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.x8),
            const _DeleteButton(),
          ],
        ),
      ),
    );
  }
}

/// One gate in the palette.
///
/// Hints show up here rather than in a wall of text: a gate no solution needs
/// is struck through and faded, and the one worth starting from is ringed.
/// The player can still place either — a hint narrows the search, it does not
/// close the door.
class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.type,
    required this.armed,
    required this.ruledOut,
    required this.suggested,
    required this.onTap,
  });

  final GateType type;
  final bool armed;
  final bool ruledOut;
  final bool suggested;
  final VoidCallback onTap;

  String get _semanticSuffix {
    if (armed) return ', armed. Tap the board to place it.';
    if (suggested) return ', suggested by the hint. Tap to pick it up.';
    if (ruledOut) return ', not needed for a par solution. Tap to pick it up.';
    return '. Tap to pick it up.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = type == GateType.constant ? '1' : type.label;

    return Semantics(
      button: true,
      selected: armed,
      label: '${type.label}$_semanticSuffix',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: ruledOut && !armed ? 0.4 : 1,
          duration: const Duration(milliseconds: 220),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            decoration: BoxDecoration(
              color: armed
                  ? colors.ember
                  : suggested
                      ? colors.sulfur
                      : colors.limestone,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: suggested && !armed ? colors.ember : colors.obsidian,
                width: suggested && !armed ? 3 : 1.5,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  decoration:
                      ruledOut && !armed ? TextDecoration.lineThrough : null,
                  decorationThickness: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deletes whatever is selected. Disabled — and visibly so — when nothing is.
class _DeleteButton extends ConsumerWidget {
  const _DeleteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardControllerProvider);
    final enabled = board.hasSelection;

    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? 'Delete selection' : 'Delete, nothing selected',
      excludeSemantics: true,
      child: IconButton(
        onPressed: enabled
            ? () {
                ref.read(soundProvider).play(Sfx.delete);
                final circuit =
                    ref.read(circuitControllerProvider.notifier);
                final wireId = board.selectedWireId;
                final componentId = board.selectedComponentId;
                if (wireId != null) {
                  circuit.removeWire(wireId);
                } else if (componentId != null) {
                  circuit.removeComponent(componentId);
                }
                ref.read(boardControllerProvider.notifier)
                    .clearSelection();
              }
            : null,
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete selection',
        style: IconButton.styleFrom(
          backgroundColor:
              enabled ? context.colors.sulfur : context.colors.limestone,
          disabledForegroundColor: context.colors.obsidianFaint,
          side: BorderSide(
            color: enabled ? context.colors.obsidian : context.colors.hairline,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
