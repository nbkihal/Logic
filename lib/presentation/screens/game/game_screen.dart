import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../application/board_controller.dart';
import '../../../application/level_scope.dart';
import '../../../application/progress_controller.dart';
import '../../../application/simulation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/levels/level_repository.dart';
import '../../../domain/engine/win_checker.dart';
import '../../../domain/models/level.dart';
import '../../canvas/circuit_canvas.dart';
import '../../widgets/hud.dart';
import '../../widgets/palette_bar.dart';
import '../../widgets/truth_table_panel.dart';
import '../../widgets/win_overlay.dart';

/// Scopes every board provider to one level.
///
/// The nested `ProviderScope` is what makes the board per-level without any
/// family plumbing: providers that depend on [levelIdProvider] are rebuilt
/// inside this scope, and torn down when the player leaves.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.levelId});

  final int levelId;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // Keyed so navigating between levels really does start a fresh board
      // rather than reusing the previous level's scope.
      key: ValueKey('level-$levelId'),
      overrides: [levelIdProvider.overrideWithValue(levelId)],
      child: const _GameView(),
    );
  }
}

class _GameView extends ConsumerStatefulWidget {
  const _GameView();

  @override
  ConsumerState<_GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<_GameView> {
  /// True once the player has dismissed the win overlay for this solve, so
  /// "Try for 3 stars" does not immediately re-open it.
  bool _winDismissed = false;
  bool _wasSolved = false;

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(levelProvider);
    if (level == null) return const _UnknownLevel();

    final report = ref.watch(solveReportProvider);
    final gates = ref.watch(gateCountProvider);

    _handleSolveTransition(level, report, gates);
    _listenForNudges();

    return Scaffold(
      backgroundColor: context.colors.pumice,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x12,
                    vertical: AppSpacing.x8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TitleRow(level: level),
                      Hud(level: level),
                      const SizedBox(height: AppSpacing.x8),
                      _StatusPill(
                        report: report,
                        onTap: () => _openTester(context, level),
                      ),
                      const SizedBox(height: AppSpacing.x8),
                      Expanded(
                        child: CircuitCanvas(
                          inputNames: level.target.inputNames,
                          outputNames: level.target.outputNames,
                        ),
                      ),
                      PaletteBar(palette: level.palette),
                    ],
                  ),
                ),
              ),
            ),
            if (report.solved && !_winDismissed)
              Positioned.fill(
                child: WinOverlay(
                  level: level,
                  stars: level.starsFor(gates),
                  gateCount: gates,
                  hasNext: const LevelRepository().next(level.id) != null,
                  onRetry: () => setState(() => _winDismissed = true),
                  onNext: () {
                    final next = const LevelRepository().next(level.id);
                    if (next != null) context.go(AppRoutes.game(next.id));
                  },
                  onLevels: () => context.go(AppRoutes.levelSelect),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Records the solve the first time a board becomes correct, and re-arms
  /// the overlay if the player breaks it and fixes it again.
  void _handleSolveTransition(Level level, SolveReport report, int gates) {
    if (report.solved == _wasSolved) return;
    _wasSolved = report.solved;

    if (!report.solved) {
      _winDismissed = false;
      return;
    }

    // Deferred: this runs during build, and writing progress touches a
    // provider, which Riverpod refuses mid-build.
    final stars = level.starsFor(gates);
    Future.microtask(
      () => ref.read(progressControllerProvider.notifier).recordSolve(
            levelId: level.id,
            stars: stars,
            gateCount: gates,
          ),
    );
  }

  /// Surfaces rejected wires and full boards as a brief message.
  void _listenForNudges() {
    ref.listen(boardControllerProvider, (previous, next) {
      if (next.nudge == null || next.nudgeToken == previous?.nudgeToken) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(next.nudge!),
            duration: const Duration(seconds: 2),
          ),
        );
    });
  }

  Future<void> _openTester(BuildContext context, Level level) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.limestone,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      // The sheet is built from the navigator's context, outside this
      // widget's level scope, so hand it the same container explicitly.
      builder: (sheetContext) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x24,
              0,
              AppSpacing.x24,
              AppSpacing.x24,
            ),
            child: SingleChildScrollView(
              child: TruthTablePanel(level: level),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        IconButton(
          onPressed: () => context.go(AppRoutes.levelSelect),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to levels',
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.name.toUpperCase(),
                style: text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                level.blurb,
                style: text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go(AppRoutes.howToPlay),
          icon: const Icon(Icons.help_outline),
          tooltip: 'How to play',
        ),
      ],
    );
  }
}

/// The live verdict, doubling as the handle that opens the truth table.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.report, required this.onTap});

  final SolveReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = statusFor(report, context.colors);

    return Semantics(
      button: true,
      label: '${status.text}. Tap to open the truth table.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: AppSpacing.x8,
          ),
          decoration: BoxDecoration(
            color: status.background,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: context.colors.obsidian, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(status.icon, size: 18),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  status.text,
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.expand_less, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnknownLevel extends StatelessWidget {
  const _UnknownLevel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.pumice,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'That level does not exist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.x16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.levelSelect),
              child: const Text('Back to levels'),
            ),
          ],
        ),
      ),
    );
  }
}
