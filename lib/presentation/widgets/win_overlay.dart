import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/progress_controller.dart';
import '../../application/sound_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/level.dart';
import 'pressable.dart';

/// Shown once a level is solved: stars, gate count against par, and where to
/// go next.
class WinOverlay extends ConsumerStatefulWidget {
  const WinOverlay({
    super.key,
    required this.level,
    required this.stars,
    required this.gateCount,
    required this.onRetry,
    required this.onInspect,
    required this.onNext,
    required this.onLevels,
    this.hasNext = true,
  });

  final Level level;
  final int stars;
  final int gateCount;
  final VoidCallback onRetry;

  /// Dismisses the overlay and leaves the solved board on screen.
  final VoidCallback onInspect;
  final VoidCallback onNext;
  final VoidCallback onLevels;
  final bool hasNext;

  @override
  ConsumerState<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends ConsumerState<WinOverlay>
    with SingleTickerProviderStateMixin {
  /// Drives the card's entrance, then the stars landing after it.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// The card takes the first third; the stars share what is left.
  static const _cardShare = 0.35;

  var _starsSounded = 0;

  @override
  void initState() {
    super.initState();
    ref.read(soundProvider).play(Sfx.win);

    if (ref.read(settingsProvider).reducedMotion) {
      _entrance.value = 1;
    } else {
      _entrance.addListener(_soundStars);
      _entrance.forward();
    }
  }

  /// Each star chimes as it lands, so the sound and the motion are one event
  /// rather than two that happen to overlap.
  void _soundStars() {
    final landed = _starsLanded;
    if (landed <= _starsSounded) return;
    _starsSounded = landed;
    if (landed <= widget.stars) ref.read(soundProvider).play(Sfx.star);
  }

  int get _starsLanded {
    if (_entrance.value <= _cardShare) return 0;
    final t = (_entrance.value - _cardShare) / (1 - _cardShare);
    return (t * 3).ceil().clamp(0, 3);
  }

  double _starScale(int index) {
    if (_entrance.value >= 1) return 1;
    final t =
        ((_entrance.value - _cardShare) / (1 - _cardShare)).clamp(0.0, 1.0);
    final own = (t * 3 - index).clamp(0.0, 1.0);
    // elasticOut at exactly zero returns zero, which paints nothing at all;
    // a hair above it keeps the star on screen as it starts.
    return Curves.elasticOut.transform(own == 0 ? 0.0001 : own);
  }

  @override
  void dispose() {
    _entrance
      ..removeListener(_soundStars)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final stars = widget.stars;
    final gateCount = widget.gateCount;
    final text = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'Level solved with $stars of 3 stars, using $gateCount gates. '
          'Par is ${level.par}.',
      child: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final t = Curves.easeOutCubic
              .transform((_entrance.value / _cardShare).clamp(0.0, 1.0));
          return ColoredBox(
            color: context.colors.obsidian.withValues(alpha: 0.55 * t),
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 40),
                child: child,
              ),
            ),
          );
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.x24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(AppSpacing.x32),
              decoration: BoxDecoration(
                color: context.colors.limestone,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SOLVED', style: text.headlineLarge),
                  const SizedBox(height: AppSpacing.x8),
                  Text(level.name, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.x24),
                  AnimatedBuilder(
                    animation: _entrance,
                    builder: (context, _) => Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.x8),
                            child: Transform.scale(
                              scale: i < stars ? _starScale(i) : 1,
                              child: Icon(
                                i < stars ? Icons.star : Icons.star_border,
                                size: 40,
                                color: i < stars
                                    ? context.colors.ember
                                    : context.colors.obsidianFaint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x16),
                  Text(
                    gateCount <= level.par
                        ? '$gateCount gates — par is ${level.par}. '
                            'Nothing wasted.'
                        : '$gateCount gates. Par is ${level.par} — there is a '
                            'tighter circuit in there.',
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.x32),
                  Wrap(
                    spacing: AppSpacing.x12,
                    runSpacing: AppSpacing.x12,
                    children: [
                      if (widget.hasNext)
                        SoundButton(
                          onPressed: widget.onNext,
                          child: (onPressed) => FilledButton(
                            onPressed: onPressed,
                            child: const Text('Next level'),
                          ),
                        ),
                      // The circuit is the reward. Getting back to it should
                      // not mean pretending you wanted to retry.
                      SoundButton(
                        onPressed: widget.onInspect,
                        child: (onPressed) => OutlinedButton(
                          onPressed: onPressed,
                          child: const Text('See it run'),
                        ),
                      ),
                      if (stars < 3)
                        SoundButton(
                          onPressed: widget.onRetry,
                          child: (onPressed) => OutlinedButton(
                            onPressed: onPressed,
                            child: const Text('Try for 3 stars'),
                          ),
                        ),
                      SoundButton(
                        onPressed: widget.onLevels,
                        child: (onPressed) => TextButton(
                          onPressed: onPressed,
                          child: const Text('All levels'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three-star row, reused on level cards.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 16});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars of 3 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < stars ? Icons.star : Icons.star_border,
              size: size,
              color: i < stars ? context.colors.ember : context.colors.obsidianFaint,
            ),
        ],
      ),
    );
  }
}

/// Small caps label used above values on cards.
TextStyle captionStyle() =>
    AppTypography.textTheme.labelSmall!.copyWith(letterSpacing: 1.5);
