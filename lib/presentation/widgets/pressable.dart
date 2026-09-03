import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/progress_controller.dart';
import '../../application/sound_controller.dart';
import '../../core/constants/animation_constants.dart';

/// Wraps anything tappable in the press feel the whole app shares: it sinks
/// under the finger, springs back on release, clicks, and buzzes.
///
/// One widget rather than a scattering of `GestureDetector`s means the timing
/// and the sound are identical everywhere, and reduced motion switches all of
/// it off in one place.
class PressableScale extends ConsumerStatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onPressed,
    this.sfx = Sfx.tap,
    this.pressedScale = 0.94,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onPressed;

  /// What this press sounds like.
  final Sfx sfx;

  /// How far it sinks. Bigger controls sink less.
  final double pressedScale;

  final bool enabled;

  @override
  ConsumerState<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends ConsumerState<PressableScale> {
  var _down = false;

  bool get _live => widget.enabled && widget.onPressed != null;

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(settingsProvider).reducedMotion;
    final speed = ref.watch(settingsProvider).animationSpeed;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _live ? (_) => _set(true) : null,
      onTapCancel: _live ? () => _set(false) : null,
      onTapUp: _live ? (_) => _set(false) : null,
      onTap: _live
          ? () {
              ref.read(soundProvider).play(widget.sfx);
              widget.onPressed!.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down && !reduced ? widget.pressedScale : 1,
        duration: reduced
            ? Duration.zero
            : AnimationConstants.scaled(
                _down
                    ? AnimationConstants.buttonPress
                    : AnimationConstants.buttonRelease,
                speed,
              ),
        // Springs past 1.0 on the way back, which is what makes it feel
        // physical rather than merely animated.
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _live ? 1 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}

/// The same press feel, applied to a Material button.
///
/// Material buttons bring their own ink and their own semantics, so they are
/// wrapped rather than replaced: the scale and the sound come from here, the
/// look stays the button's own.
class SoundButton extends ConsumerWidget {
  const SoundButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.sfx = Sfx.tap,
    this.pressedScale = 0.96,
  });

  /// A `FilledButton`, `OutlinedButton`, `IconButton` — whatever fits.
  ///
  /// Built by a callback so the wrapper owns the tap: the button itself is
  /// handed a press that has already clicked.
  final Widget Function(VoidCallback? onPressed) child;

  final VoidCallback? onPressed;
  final Sfx sfx;
  final double pressedScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(settingsProvider).reducedMotion;
    final press = onPressed == null
        ? null
        : () {
            ref.read(soundProvider).play(sfx);
            onPressed!.call();
          };

    if (reduced) return child(press);
    return _Springy(pressedScale: pressedScale, builder: child, onTap: press);
  }
}

class _Springy extends StatefulWidget {
  const _Springy({
    required this.pressedScale,
    required this.builder,
    required this.onTap,
  });

  final double pressedScale;
  final Widget Function(VoidCallback? onPressed) builder;
  final VoidCallback? onTap;

  @override
  State<_Springy> createState() => _SpringyState();
}

class _SpringyState extends State<_Springy> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null) setState(() => _down = true);
      },
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: _down
            ? AnimationConstants.buttonPress
            : AnimationConstants.buttonRelease,
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.builder(widget.onTap),
      ),
    );
  }
}
