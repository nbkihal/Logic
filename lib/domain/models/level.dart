import 'gate_type.dart';
import 'truth_table.dart';

/// One hand-designed stage (CLAUDE.md §8).
class Level {
  const Level({
    required this.id,
    required this.name,
    required this.chapter,
    required this.blurb,
    required this.inputCount,
    required this.outputCount,
    required this.palette,
    required this.target,
    required this.par,
    this.solutionGates = const {},
    this.showTargetTable = true,
    this.gateLimit,
  });

  final int id;
  final String name;

  /// The arc this level belongs to. Chapters group the stage list and mark
  /// where the game deliberately changes subject: the difficulty curve runs
  /// *within* a chapter, and resets at each new one (CLAUDE.md §8).
  final String chapter;

  /// One-line teaching hook.
  final String blurb;

  final int inputCount;
  final int outputCount;

  /// Which component types this level offers.
  final Set<GateType> palette;

  final TruthTable target;

  /// Gate count for three stars.
  final int par;

  /// When false the level is a black box — Hint reveals the table.
  final bool showTargetTable;

  /// Optional hard cap on placeable gates. Null means unlimited.
  final int? gateLimit;

  /// What one known par-sized solution is built from: gate type to how many
  /// of it. This is the evidence behind the hints — which palette entries a
  /// player can safely ignore, and which one is worth reaching for first —
  /// so a hint can never point somewhere the level does not go.
  ///
  /// It describes *a* solution, not the only one; the hints say so.
  final Map<GateType, int> solutionGates;

  /// Palette entries no known par solution needs. Hint two crosses these off.
  Set<GateType> get unusedGates =>
      palette.difference(solutionGates.keys.toSet());

  /// The gate to reach for first: the one the solution leans on most, ties
  /// broken by the palette's own teaching order.
  GateType? get keystoneGate {
    if (solutionGates.isEmpty) return null;
    final entries = solutionGates.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.index.compareTo(b.key.index);
      });
    return entries.first.key;
  }

  /// Star band for a solved circuit of [gateCount] gates (CLAUDE.md §7,
  /// with the §20 recommended default for the two-star band).
  int starsFor(int gateCount) {
    if (gateCount <= par) return 3;
    if (gateCount <= par + (par / 2).ceil()) return 2;
    return 1;
  }

  /// Sanity: the declared shape matches the target table.
  bool get isWellFormed =>
      target.isWellFormed &&
      target.inputCount == inputCount &&
      target.outputCount == outputCount;

  @override
  String toString() => 'Level($id, $name)';
}
