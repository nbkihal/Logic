import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/board_controller.dart';
import '../../application/circuit_controller.dart';
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
  const PaletteBar({
    super.key,
    required this.levelId,
    required this.palette,
  });

  final int levelId;
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
    final board = ref.watch(boardControllerProvider(levelId));
    final available = _order.where(palette.contains).toList();

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
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.x8),
                itemBuilder: (context, index) {
                  final type = available[index];
                  return _PaletteChip(
                    type: type,
                    armed: board.armed == type,
                    onTap: () =>
                        ref.read(boardControllerProvider(levelId).notifier)
                            .arm(type),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.x8),
            _DeleteButton(levelId: levelId),
          ],
        ),
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.type,
    required this.armed,
    required this.onTap,
  });

  final GateType type;
  final bool armed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: armed,
      label: armed
          ? '${type.label}, armed. Tap the board to place it.'
          : '${type.label}. Tap to pick it up.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
          decoration: BoxDecoration(
            color: armed ? AppColors.ember : AppColors.limestone,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.obsidian, width: 1.5),
          ),
          child: Center(
            child: Text(
              type == GateType.constant ? '1' : type.label,
              style: AppTypography.textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}

/// Deletes whatever is selected. Disabled — and visibly so — when nothing is.
class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.levelId});

  final int levelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardControllerProvider(levelId));
    final enabled = board.hasSelection;

    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? 'Delete selection' : 'Delete, nothing selected',
      excludeSemantics: true,
      child: IconButton(
        onPressed: enabled
            ? () {
                final circuit =
                    ref.read(circuitControllerProvider(levelId).notifier);
                final wireId = board.selectedWireId;
                final componentId = board.selectedComponentId;
                if (wireId != null) {
                  circuit.removeWire(wireId);
                } else if (componentId != null) {
                  circuit.removeComponent(componentId);
                }
                ref.read(boardControllerProvider(levelId).notifier)
                    .clearSelection();
              }
            : null,
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete selection',
        style: IconButton.styleFrom(
          backgroundColor:
              enabled ? AppColors.sulfur : AppColors.limestone,
          disabledForegroundColor: AppColors.obsidianFaint,
          side: BorderSide(
            color: enabled ? AppColors.obsidian : AppColors.hairline,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
