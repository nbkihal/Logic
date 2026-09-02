import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/caldera_scaffold.dart';

/// The rules, in the order a new player meets them.
///
/// Deliberately short: the levels teach Boolean logic, so this only has to
/// teach the *controls* and the one idea the game is built on — make the
/// lamps match the table.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _goal = [
    _Step(
      icon: Icons.flag_outlined,
      title: 'The goal',
      body: 'Every level gives you switches on the left and lamps on the '
          'right, plus a target truth table. Wire up gates until the lamps '
          'match the table for every row.',
    ),
    _Step(
      icon: Icons.table_rows_outlined,
      title: 'Read the table',
      body: 'Tap the status bar above the board to open it. Each row is one '
          'combination of the switches: "want" is what the level asks for, '
          '"got" is what your circuit currently does. Rows marked ! are the '
          'ones still wrong.',
    ),
  ];

  static const _controls = [
    _Step(
      icon: Icons.add_box_outlined,
      title: 'Place a gate',
      body: 'Tap a gate in the bar at the bottom to pick it up — the board '
          'outline turns orange. Then tap an empty spot to drop it. Tap the '
          'gate again to put it back.',
    ),
    _Step(
      icon: Icons.timeline,
      title: 'Wire it up',
      body: 'Tap the dot on the right of a gate (its output), then tap a dot '
          'on the left of another (an input). One wire per input, but an '
          'output can feed as many inputs as you like.',
    ),
    _Step(
      icon: Icons.toggle_on_outlined,
      title: 'Flip a switch',
      body: 'Tap an input pin to flip it between 0 and 1. Watch the wires '
          'light up: orange carries a 1, dark carries a 0, and a dashed grey '
          'wire is not connected to anything yet.',
    ),
    _Step(
      icon: Icons.delete_outline,
      title: 'Move and delete',
      body: 'Press and hold a gate to drag it somewhere else. Tap a gate or '
          'a wire to select it, then hit the bin in the bottom-right. Undo '
          'and redo are in the row above the board.',
    ),
    _Step(
      icon: Icons.zoom_out_map,
      title: 'Get around',
      body: 'Drag the empty board to pan, pinch to zoom, or use the buttons '
          'in the corner. The middle button re-frames everything.',
    ),
  ];

  static const _scoring = [
    _Step(
      icon: Icons.star_outline,
      title: 'Stars',
      body: 'One star for solving it. Three stars for solving it in par gates '
            'or fewer — par is shown next to your gate count. Switches, lamps '
            'and constants are free; only gates count.',
    ),
    _Step(
      icon: Icons.lock_open,
      title: 'Unlocking',
      body: 'One star opens the next level. You can always come back and '
          'hunt for a tighter circuit.',
    ),
    _Step(
      icon: Icons.warning_amber_outlined,
      title: 'Two things to watch',
      body: 'An unconnected input is "X" — undefined, not zero. And a circuit '
          'that loops back into itself cannot be worked out at all; the game '
          'will tell you and highlight the loop.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return CalderaScaffold(
      onBack: () => context.go(AppRoutes.home),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.x40),
        children: [
          const SizedBox(height: AppSpacing.x16),
          Text('HOW TO PLAY', style: text.headlineLarge),
          const SizedBox(height: AppSpacing.x24),
          const _Section(title: 'The idea', steps: _goal),
          const _Section(title: 'Controls', steps: _controls),
          const _Section(title: 'Scoring', steps: _scoring),
          const SizedBox(height: AppSpacing.x24),
          const _Legend(),
          const SizedBox(height: AppSpacing.x24),
          FilledButton(
            onPressed: () => context.go(AppRoutes.levelSelect),
            child: const Text('Start playing'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.steps});

  final String title;
  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: AppSpacing.x8),
        ...steps,
        const SizedBox(height: AppSpacing.x24),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x8),
      padding: const EdgeInsets.all(AppSpacing.x20),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: AppSpacing.x16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                const SizedBox(height: AppSpacing.x4),
                Text(body, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the colours and glyphs on the board mean — the same information the
/// board itself carries twice over, so nobody has to guess.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x20),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SIGNALS', style: text.labelSmall?.copyWith(letterSpacing: 2)),
          const SizedBox(height: AppSpacing.x12),
          const _LegendRow(
            colour: SignalColors.high,
            glyph: '1',
            label: 'Carrying a one — the wire glows.',
          ),
          const _LegendRow(
            colour: SignalColors.low,
            glyph: '0',
            label: 'Carrying a zero — the wire is dark.',
          ),
          const _LegendRow(
            colour: SignalColors.floating,
            glyph: 'X',
            label: 'Nothing connected — the wire is dashed.',
            dashed: true,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.colour,
    required this.glyph,
    required this.label,
    this.dashed = false,
  });

  final Color colour;
  final String glyph;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: dashed ? null : colour,
              borderRadius: BorderRadius.circular(4),
              border: dashed ? Border.all(color: colour) : null,
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          SizedBox(
            width: 20,
            child: Text(
              glyph,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
