import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../application/progress_controller.dart';
import '../../../core/constants/animation_constants.dart';
import '../../../core/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/levels/level_repository.dart';
import '../../widgets/pressable.dart';

/// Title screen. One big way in, everything else deliberately quieter.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(progressProvider);
    final levelCount = const LevelRepository().count;
    final resume = progress.highestUnlocked(levelCount);
    final started = progress.totalStars > 0;
    final wide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: context.colors.pumice,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.x24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const IdleCircuit(),
                  const SizedBox(height: AppSpacing.x20),
                  Text(
                    'LOGIC',
                    textAlign: TextAlign.center,
                    style: (wide ? text.displayLarge : text.displaySmall)
                        ?.copyWith(color: context.colors.ember),
                  ),
                  Text(
                    'CIRCUIT BUILDER',
                    textAlign: TextAlign.center,
                    style: text.labelMedium?.copyWith(letterSpacing: 3),
                  ),
                  const SizedBox(height: AppSpacing.x20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Text(
                      'Wire gates together until the lamps match the table. '
                      'Sixty-three stages, from a single NOT gate to a '
                      'two-bit multiplier.',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x32),

                  // The one thing a returning player came here to press. It
                  // is the biggest target on the screen on purpose;
                  // everything below it is a detour.
                  PrimaryAction(
                    label: started ? 'Continue' : 'Start',
                    caption: started ? 'Level $resume' : 'Level 1 — Invert It',
                    onPressed: () => context.go(AppRoutes.game(resume)),
                  ),
                  const SizedBox(height: AppSpacing.x20),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.x8,
                    runSpacing: AppSpacing.x8,
                    children: [
                      SoundButton(
                        onPressed: () => context.go(AppRoutes.levelSelect),
                        child: (onPressed) => OutlinedButton(
                          onPressed: onPressed,
                          style: _smallStyle(context),
                          child: const Text('Levels'),
                        ),
                      ),
                      SoundButton(
                        onPressed: () => context.go(AppRoutes.howToPlay),
                        child: (onPressed) => OutlinedButton(
                          onPressed: onPressed,
                          style: _smallStyle(context),
                          child: const Text('How to play'),
                        ),
                      ),
                      SoundButton(
                        onPressed: () => context.go(AppRoutes.settings),
                        child: (onPressed) => TextButton(
                          onPressed: onPressed,
                          style: _smallStyle(context),
                          child: const Text('Settings'),
                        ),
                      ),
                    ],
                  ),
                  if (started) ...[
                    const SizedBox(height: AppSpacing.x24),
                    Text(
                      '${progress.totalStars} of ${levelCount * 3} stars — '
                      'up to level $resume.',
                      textAlign: TextAlign.center,
                      style: text.bodySmall
                          ?.copyWith(color: context.colors.obsidianMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Secondary actions sit a size below the primary, in every dimension.
  ButtonStyle _smallStyle(BuildContext context) => ButtonStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: AppSpacing.x8,
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.labelMedium,
        ),
      );
}

/// The hero button: a wide Ember pill with a slow halo behind it.
class PrimaryAction extends ConsumerStatefulWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.caption,
    required this.onPressed,
  });

  final String label;
  final String caption;
  final VoidCallback onPressed;

  @override
  ConsumerState<PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends ConsumerState<PrimaryAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AnimationConstants.idleShimmer,
  );

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  /// Only loops while motion is allowed — a forever-running ticker is what
  /// "remove animations" is asking the app not to do.
  void _follow(Motion motion) {
    if (motion.enabled && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!motion.enabled && _breath.isAnimating) {
      _breath.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final motion = motionOf(context, ref);
    _follow(motion);
    final reduced = !motion.enabled;

    return Semantics(
      button: true,
      label: '${widget.label}. ${widget.caption}.',
      excludeSemantics: true,
      child: PressableScale(
        pressedScale: 0.97,
        onPressed: widget.onPressed,
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, child) {
            // A slow glow, so the screen never looks switched off.
            final t = reduced ? 0.0 : Curves.easeInOut.transform(_breath.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: [
                  BoxShadow(
                    color: colors.ember.withValues(alpha: 0.18 + t * 0.22),
                    blurRadius: 24 + t * 26,
                    spreadRadius: t * 4,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 250),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x40,
              vertical: AppSpacing.x16,
            ),
            decoration: BoxDecoration(
              color: colors.ember,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: colors.obsidian, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: text.headlineMedium?.copyWith(color: colors.onEmber),
                ),
                Text(
                  widget.caption,
                  style: text.labelSmall?.copyWith(
                    color: colors.onEmber.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A little NAND blinking away above the title, so the app is alive before
/// the player has touched anything (CLAUDE.md §11).
class IdleCircuit extends ConsumerStatefulWidget {
  const IdleCircuit({super.key});

  @override
  ConsumerState<IdleCircuit> createState() => _IdleCircuitState();
}

class _IdleCircuitState extends ConsumerState<IdleCircuit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = motionOf(context, ref);
    if (motion.enabled && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!motion.enabled && _pulse.isAnimating) {
      _pulse.stop();
    }
    final reduced = !motion.enabled;
    final colors = context.colors;

    return SizedBox(
      height: 80,
      width: 250,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => CustomPaint(
          painter: _IdlePainter(
            t: reduced ? 0.75 : _pulse.value,
            ink: colors.obsidian,
            live: colors.signalHigh,
            dead: colors.signalLow,
            fill: colors.limestone,
            bloom: colors.bloom,
          ),
        ),
      ),
    );
  }
}

class _IdlePainter extends CustomPainter {
  _IdlePainter({
    required this.t,
    required this.ink,
    required this.live,
    required this.dead,
    required this.fill,
    required this.bloom,
  });

  final double t;
  final Color ink;
  final Color live;
  final Color dead;
  final Color fill;
  final Color bloom;

  @override
  void paint(Canvas canvas, Size size) {
    // Two pins into a NAND into a lamp. Both pins go high, the gate answers
    // low, and a dot carries the answer across — the game in one gesture.
    final midY = size.height / 2;
    final gate = Rect.fromCenter(
      center: Offset(size.width * 0.5, midY),
      width: 62,
      height: 38,
    );
    final lamp = Offset(size.width - 18, midY);
    final pins = [Offset(16, midY - 15), Offset(16, midY + 15)];

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ink;

    // Inputs are high for the second half of the cycle; NAND inverts, so the
    // lamp is lit for the first half.
    final inputsHigh = t >= 0.5;
    final travel = (t * 2) % 1;

    for (final pin in pins) {
      canvas.drawPath(
        Path()
          ..moveTo(pin.dx + 8, pin.dy)
          ..lineTo(gate.left - 12, pin.dy)
          ..lineTo(gate.left, midY),
        stroke..color = inputsHigh ? live : dead,
      );
      canvas
        ..drawCircle(pin, 7, Paint()..color = inputsHigh ? live : fill)
        ..drawCircle(pin, 7, outline);
    }

    canvas.drawLine(
      Offset(gate.right, midY),
      Offset(lamp.dx - 11, midY),
      stroke..color = inputsHigh ? dead : live,
    );

    // The travelling dot: seeing the value move *is* the explanation.
    canvas.drawCircle(
      Offset(gate.right + (lamp.dx - 11 - gate.right) * travel, midY),
      4,
      Paint()..color = inputsHigh ? dead : live,
    );

    final body = RRect.fromRectAndRadius(gate, const Radius.circular(10));
    canvas
      ..drawRRect(body, Paint()..color = fill)
      ..drawRRect(body, outline);

    final label = TextPainter(
      text: TextSpan(
        text: 'NAND',
        style: TextStyle(
          color: ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, gate.center - Offset(label.width / 2, label.height / 2));

    if (!inputsHigh) canvas.drawCircle(lamp, 16, Paint()..color = bloom);
    canvas
      ..drawCircle(lamp, 9, Paint()..color = inputsHigh ? fill : live)
      ..drawCircle(lamp, 9, outline);
  }

  @override
  bool shouldRepaint(_IdlePainter old) =>
      old.t != t || old.ink != ink || old.live != live;
}
