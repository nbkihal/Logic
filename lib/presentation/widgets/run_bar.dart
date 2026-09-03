import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_controller.dart';
import '../../application/simulation_provider.dart';
import '../../application/sound_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/level.dart';

/// A transport for the finished circuit: play, step, and see which row of the
/// table is on the pins right now.
///
/// Solving proves the circuit is right. This is for looking at *why* — the
/// board runs its own truth table while the player watches the signals move,
/// which is the thing a static table cannot show.
class RunBar extends ConsumerWidget {
  const RunBar({super.key, required this.level});

  final Level level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider);
    final controller = ref.read(runProvider.notifier);
    final report = ref.watch(solveReportProvider);
    final sound = ref.read(soundProvider);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final rows = level.target.rowCount;
    final inputs = level.target.inputsAt(run.row);
    final matches =
        run.row < report.rows.length && report.rows[run.row].matches;

    return Semantics(
      container: true,
      label: 'Run the circuit. Row ${run.row + 1} of $rows.',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x4,
        ),
        decoration: BoxDecoration(
          color: colors.limestone,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: colors.obsidian, width: 1.5),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                sound.play(Sfx.tap);
                controller.stepBack();
              },
              icon: const Icon(Icons.skip_previous),
              tooltip: 'Previous row',
            ),
            IconButton(
              onPressed: () {
                sound.play(run.playing ? Sfx.tap : Sfx.toggle);
                controller.toggle();
              },
              icon: Icon(run.playing ? Icons.pause : Icons.play_arrow),
              tooltip: run.playing ? 'Pause' : 'Run every row',
              style: IconButton.styleFrom(
                backgroundColor: run.playing ? colors.ember : colors.sulfur,
                side: BorderSide(color: colors.obsidian, width: 1.5),
              ),
            ),
            IconButton(
              onPressed: () {
                sound.play(Sfx.tap);
                controller.step();
              },
              icon: const Icon(Icons.skip_next),
              tooltip: 'Next row',
            ),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROW ${run.row + 1} / $rows',
                    style: text.labelSmall?.copyWith(letterSpacing: 1.5),
                  ),
                  Text(
                    // The combination on the pins, spelled out, so the bar
                    // says the same thing the board is showing.
                    [
                      for (var i = 0; i < inputs.length; i++)
                        '${level.target.inputNames[i]}='
                            '${inputs[i] ? 1 : 0}',
                    ].join('  '),
                    style: AppTypography.pinLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              matches ? Icons.check : Icons.close,
              size: 18,
              color: matches ? colors.ember : colors.obsidianMuted,
            ),
          ],
        ),
      ),
    );
  }
}
