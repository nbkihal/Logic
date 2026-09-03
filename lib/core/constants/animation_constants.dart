/// Durations from the animation catalogue (CLAUDE.md §13.1).
///
/// Every duration is scaled at use-site by `settings.animationSpeed`
/// (0.5x-2.0x) and collapses to [instant] under reduced motion.
abstract final class AnimationConstants {
  static const springPlace = Duration(milliseconds: 320);
  static const paletteLift = Duration(milliseconds: 120);
  static const portHighlight = Duration(milliseconds: 150);

  /// Per wire hop, in topological order.
  static const signalHop = Duration(milliseconds: 260);
  static const gateFire = Duration(milliseconds: 180);
  static const lampGlowIn = Duration(milliseconds: 220);
  static const lampGlowOut = Duration(milliseconds: 180);
  static const toggleSwitch = Duration(milliseconds: 140);
  static const mismatchSpark = Duration(milliseconds: 300);
  static const cyclePulse = Duration(milliseconds: 400);
  static const deletePoof = Duration(milliseconds: 200);

  /// Stagger between truth-table rows during a sweep.
  static const tableRowStagger = Duration(milliseconds: 60);
  static const winCascade = Duration(milliseconds: 900);
  static const starPop = Duration(milliseconds: 260);
  static const starStagger = Duration(milliseconds: 120);
  static const idleShimmer = Duration(milliseconds: 2400);

  /// Idle threshold before the Home demo starts breathing.
  static const idleBeforeShimmer = Duration(seconds: 6);

  /// Cross-fade when the player picks a different palette.
  static const themeSweep = Duration(milliseconds: 420);

  /// A button's press-in, and the release that springs back.
  static const buttonPress = Duration(milliseconds: 90);
  static const buttonRelease = Duration(milliseconds: 240);

  /// One input combination during a solved-board run.
  static const runStep = Duration(milliseconds: 520);

  static const instant = Duration.zero;

  static const minSpeed = 0.5;
  static const maxSpeed = 2.0;
  static const defaultSpeed = 1.0;

  /// Scales [base] by [speed]; a higher speed means a shorter duration.
  static Duration scaled(Duration base, double speed) => Duration(
        microseconds: (base.inMicroseconds / speed).round(),
      );
}
