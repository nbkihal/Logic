import 'gate_type.dart';
import 'truth_table.dart';

/// One hand-designed stage (CLAUDE.md §8).
class Level {
  const Level({
    required this.id,
    required this.name,
    required this.blurb,
    required this.inputCount,
    required this.outputCount,
    required this.palette,
    required this.target,
    required this.par,
    this.showTargetTable = true,
    this.gateLimit,
  });

  final int id;
  final String name;

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
