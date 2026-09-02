import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/simulation_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/engine/win_checker.dart';
import '../../domain/models/level.dart';

/// How the board is doing, in one line.
///
/// Incomplete is deliberately not "wrong": a half-built circuit is unfinished,
/// and saying so keeps the feedback honest (CLAUDE.md §6.3).
({String text, Color background, IconData icon}) statusFor(
  SolveReport report,
) =>
    switch (report.status) {
      SolveStatus.solved => (
          text: 'Solved',
          background: AppColors.ember,
          icon: Icons.check_circle_outline,
        ),
      SolveStatus.incomplete => (
          text: 'Not finished — some inputs are unconnected',
          background: AppColors.sulfur,
          icon: Icons.link_off,
        ),
      SolveStatus.cyclic => (
          text: 'This wiring loops back on itself',
          background: AppColors.sulfur,
          icon: Icons.autorenew,
        ),
      SolveStatus.mismatched => (
          text: '${report.failingRows.length} of ${report.rows.length} '
              'rows still wrong',
          background: AppColors.limestone,
          icon: Icons.error_outline,
        ),
      SolveStatus.malformed => (
          text: 'Board does not match this level',
          background: AppColors.limestone,
          icon: Icons.help_outline,
        ),
    };

/// Target versus current, row by row, with the failing rows called out.
class TruthTablePanel extends ConsumerWidget {
  const TruthTablePanel({super.key, required this.level});

  final Level level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(solveReportProvider);
    final revealed = ref.watch(hintRevealedProvider);
    final hidden = !level.showTargetTable && !revealed;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text('TRUTH TABLE', style: text.headlineSmall)),
            if (hidden)
              FilledButton(
                onPressed: () => ref
                    .read(hintRevealedProvider.notifier)
                    .reveal(),
                child: const Text('Reveal'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x12),
        if (hidden)
          Text(
            'This one is a black box. Flip the inputs, watch the lamp, and '
            'work out the rule — or reveal the table.',
            style: text.bodyMedium,
          )
        else
          _Table(level: level, report: report),
      ],
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.level, required this.report});

  final Level level;
  final SolveReport report;

  @override
  Widget build(BuildContext context) {
    final table = level.target;
    const style = AppTypography.pinLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Row(
          cells: [
            ...table.inputNames,
            ...table.outputNames.map((name) => 'want $name'),
            ...table.outputNames.map((name) => 'got $name'),
          ],
          style: AppTypography.textTheme.labelSmall!,
          background: AppColors.pumice,
        ),
        for (var i = 0; i < table.rowCount; i++)
          _Row(
            cells: [
              ...table.inputsAt(i).map((b) => b ? '1' : '0'),
              ...table.outputsAt(i).map((b) => b ? '1' : '0'),
              ...List<String>.generate(
                table.outputCount,
                (j) => _actual(i, j),
              ),
            ],
            style: style,
            background: _rowColour(i),
            // A failing row is marked by weight and an arrow as well as by
            // fill, so it reads without colour.
            marker: _matches(i) ? null : '!',
          ),
      ],
    );
  }

  bool _matches(int row) =>
      row < report.rows.length && report.rows[row].matches;

  String _actual(int row, int output) {
    if (row >= report.rows.length) return '-';
    final values = report.rows[row].actual;
    if (output >= values.length) return '-';
    return values[output].glyph;
  }

  Color _rowColour(int row) {
    if (report.rows.isEmpty) return AppColors.limestone;
    if (report.status == SolveStatus.solved) return AppColors.sulfur;
    return _matches(row) ? AppColors.limestone : AppColors.pumice;
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.cells,
    required this.style,
    required this.background,
    this.marker,
  });

  final List<String> cells;
  final TextStyle style;
  final Color background;
  final String? marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              marker ?? '',
              style: style.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final cell in cells)
            Expanded(
              child: Text(cell, style: style, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
