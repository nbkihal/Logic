import 'package:flutter/material.dart';

import 'constants/animation_constants.dart';

/// How much motion this screen is allowed, and how fast.
///
/// Two switches feed one answer: the player's own reduced-motion toggle, and
/// the operating system's "remove animations" accessibility setting, which
/// CLAUDE.md §16 asks the app to respect where available. Anything that moves
/// asks here rather than reading the setting directly, so neither switch can
/// be forgotten in one corner of the UI.
@immutable
class Motion {
  const Motion({required this.enabled, required this.speed});

  /// False when either switch says no. Ongoing, looping animations must not
  /// start at all in that case; one-shot state changes simply land instantly.
  final bool enabled;

  /// 0.5x to 2.0x, from settings. Higher is quicker.
  final double speed;

  /// [base], scaled — or zero when motion is off.
  Duration call(Duration base) =>
      enabled ? AnimationConstants.scaled(base, speed) : Duration.zero;

  /// A curve worth using, or a linear one when motion is off.
  Curve curve(Curve preferred) => enabled ? preferred : Curves.linear;

  static Motion of(BuildContext context, {required bool reducedMotion,
      required double speed}) {
    final osSaysNo = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Motion(enabled: !reducedMotion && !osSaysNo, speed: speed);
  }
}
