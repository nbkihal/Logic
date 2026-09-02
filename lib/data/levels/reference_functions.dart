/// Reference implementations of every level's target function.
///
/// The hard-coded tables in `levels_data.dart` are what the game ships; these
/// functions are the independent second opinion. A unit test recomputes every
/// table from the function here and asserts equality, so a mistyped target row
/// cannot reach a player (CLAUDE.md §15).
///
/// Every function takes inputs in truth-table column order (first input is the
/// most-significant bit) and returns outputs in column order.
typedef LogicFunction = List<bool> Function(List<bool> inputs);

abstract final class ReferenceFunctions {
  /// Level 1 — NOT.
  static List<bool> invert(List<bool> i) => [!i[0]];

  /// Level 2 — AND.
  static List<bool> conjunction(List<bool> i) => [i[0] && i[1]];

  /// Level 3 — OR.
  static List<bool> disjunction(List<bool> i) => [i[0] || i[1]];

  /// Levels 4 and 7's complement — NAND.
  static List<bool> nand(List<bool> i) => [!(i[0] && i[1])];

  /// Level 5 — XOR.
  static List<bool> exclusiveOr(List<bool> i) => [i[0] != i[1]];

  /// Level 6 — half adder: SUM, CARRY.
  static List<bool> halfAdder(List<bool> i) => [i[0] != i[1], i[0] && i[1]];

  /// Level 9 — material implication, A -> B. The hidden black-box function.
  static List<bool> implication(List<bool> i) => [!i[0] || i[1]];

  /// Level 10 — majority of three.
  static List<bool> majority(List<bool> i) =>
      [i.where((b) => b).length >= 2];

  /// Level 11 — full adder: SUM, CARRY.
  static List<bool> fullAdder(List<bool> i) {
    final highs = i.where((b) => b).length;
    return [highs.isOdd, highs >= 2];
  }

  /// Level 12 — 2:1 multiplexer over (A, B, S): S ? B : A.
  static List<bool> selector(List<bool> i) => [i[2] ? i[1] : i[0]];

  /// Level 13 — 2-bit magnitude comparator over (A1, A0, B1, B0):
  /// A > B, A == B, A < B.
  static List<bool> compare2Bit(List<bool> i) {
    final a = (i[0] ? 2 : 0) + (i[1] ? 1 : 0);
    final b = (i[2] ? 2 : 0) + (i[3] ? 1 : 0);
    return [a > b, a == b, a < b];
  }

  /// Expands [fn] over every input combination, first input as MSB.
  static List<List<bool>> tabulate(int inputCount, LogicFunction fn) => [
        for (var row = 0; row < (1 << inputCount); row++)
          fn([
            for (var bit = 0; bit < inputCount; bit++)
              (row >> (inputCount - 1 - bit)) & 1 == 1,
          ]),
      ];

  /// The reference function backing each level id.
  static const Map<int, LogicFunction> byLevelId = {
    1: invert,
    2: conjunction,
    3: disjunction,
    4: nand,
    5: exclusiveOr,
    6: halfAdder,
    7: conjunction,
    8: disjunction,
    9: implication,
    10: majority,
    11: fullAdder,
    12: selector,
    13: compare2Bit,
  };
}
