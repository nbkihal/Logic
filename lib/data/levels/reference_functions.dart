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
  // ------------------------------------------------------------- primitives

  /// Level 1 — NOT. Also levels 14 (NOR-only) and 51 (no inverter offered):
  /// same function, a different restriction each time.
  static List<bool> invert(List<bool> i) => [!i[0]];

  /// Level 2 — AND. Also levels 7 and 16, built from a single gate type.
  static List<bool> conjunction(List<bool> i) => [i[0] && i[1]];

  /// Level 3 — OR. Also levels 8, 15 and 52.
  static List<bool> disjunction(List<bool> i) => [i[0] || i[1]];

  /// Levels 4 and 7's complement — NAND.
  static List<bool> nand(List<bool> i) => [!(i[0] && i[1])];

  /// Level 5 — XOR. Also levels 17, 18 and 53.
  static List<bool> exclusiveOr(List<bool> i) => [i[0] != i[1]];

  /// Level 6 — half adder: SUM, CARRY.
  static List<bool> halfAdder(List<bool> i) => [i[0] != i[1], i[0] && i[1]];

  /// Level 9 — material implication, A -> B. The hidden black-box function.
  static List<bool> implication(List<bool> i) => [!i[0] || i[1]];

  /// Level 10 — majority of three. Also level 55, from NOR alone.
  static List<bool> majority(List<bool> i) => [_count(i) >= 2];

  /// Level 11 — full adder: SUM, CARRY.
  static List<bool> fullAdder(List<bool> i) {
    final highs = _count(i);
    return [highs.isOdd, highs >= 2];
  }

  /// Levels 12 and 54 — 2:1 multiplexer over (A, B, S): S ? B : A.
  static List<bool> selector(List<bool> i) => [i[2] ? i[1] : i[0]];

  /// Level 13 — 2-bit magnitude comparator over (A1, A0, B1, B0):
  /// A > B, A == B, A < B.
  static List<bool> compare2Bit(List<bool> i) {
    final a = _value(i.sublist(0, 2));
    final b = _value(i.sublist(2, 4));
    return [a > b, a == b, a < b];
  }

  // ---------------------------------------------------------- everyday logic

  /// Level 19 — a hallway lamp wired to three doorways: any switch flips it.
  static List<bool> threeWaySwitch(List<bool> i) => [_count(i).isOdd];

  /// Level 20 — (KEY, BELT, SEAT): chime when the car is running, someone is
  /// sitting there, and the belt is not fastened.
  static List<bool> seatbeltAlarm(List<bool> i) => [i[0] && i[2] && !i[1]];

  /// Level 21 — (SMOKE, HEAT, TEST): spray on both sensors, or on a drill.
  static List<bool> sprinkler(List<bool> i) => [i[2] || (i[0] && i[1])];

  /// Level 22 — (UP, DOWN, DOORS): move only on exactly one call, doors shut.
  static List<bool> elevator(List<bool> i) => [(i[0] != i[1]) && !i[2]];

  /// Level 23 — (COIN, SELECT, STOCK): DISPENSE, REFUND.
  static List<bool> vendingMachine(List<bool> i) => [
        i[0] && i[1] && i[2],
        i[0] && !(i[1] && i[2]),
      ];

  /// Level 24 — (CAR, PED, NIGHT): GREEN for traffic, WALK for pedestrians.
  static List<bool> trafficCrossing(List<bool> i) => [
        !i[1] && (i[0] || i[2]),
        i[1] && !i[2],
      ];

  /// Level 25 — (KEY A, KEY B, KEY C, MANAGER): two keyholders agree, or the
  /// manager overrides.
  static List<bool> safeDeposit(List<bool> i) =>
      [i[3] || _count(i.sublist(0, 3)) >= 2];

  // ------------------------------------------------------------ counting bits

  /// Level 26 — exactly one of three is high.
  static List<bool> exactlyOne(List<bool> i) => [_count(i) == 1];

  /// Level 27 — all three agree, high or low.
  static List<bool> allOrNothing(List<bool> i) {
    final highs = _count(i);
    return [highs == 0 || highs == 3];
  }

  /// Level 28 — how many of three are high, as a 2-bit number.
  static List<bool> countToTwo(List<bool> i) => _bits(_count(i), 2);

  /// Level 29 — how many of four are high, as a 3-bit number.
  static List<bool> countToFour(List<bool> i) => _bits(_count(i), 3);

  /// Level 30 — parity of four bits.
  static List<bool> parityOfFour(List<bool> i) => [_count(i).isOdd];

  /// Level 31 — exactly two of four are high.
  static List<bool> exactlyTwo(List<bool> i) => [_count(i) == 2];

  /// Level 32 — three or more of four are high.
  static List<bool> atLeastThree(List<bool> i) => [_count(i) >= 3];

  // -------------------------------------------------------- choosing, routing

  /// Level 33 — 2-to-4 decoder: light the one lamp the number names.
  static List<bool> decoder2To4(List<bool> i) {
    final line = _value(i);
    return [for (var n = 0; n < 4; n++) n == line];
  }

  /// Level 34 — 1-to-2 demultiplexer over (D, S): send D down one of two paths.
  static List<bool> demultiplexer(List<bool> i) => [i[0] && !i[1], i[0] && i[1]];

  /// Level 35 — (A, B, EN): both channels pass only while enabled.
  static List<bool> gatedPair(List<bool> i) => [i[0] && i[2], i[1] && i[2]];

  /// Level 36 — (A, B, S): pass the pair straight through, or crossed over.
  static List<bool> swapOnDemand(List<bool> i) =>
      [i[2] ? i[1] : i[0], i[2] ? i[0] : i[1]];

  /// Level 37 — 4-to-2 priority encoder over (D3, D2, D1, D0): VALID and the
  /// index of the highest request that is asserted.
  static List<bool> priorityEncoder(List<bool> i) {
    final highest = i.indexOf(true); // D3 first, so the first true wins
    if (highest < 0) return const [false, false, false];
    return [true, ..._bits(3 - highest, 2)];
  }

  /// Level 38 — (A, B, S, EN): a two-channel crossbar behind an enable.
  static List<bool> crossbar(List<bool> i) => [
        i[3] && (i[2] ? i[1] : i[0]),
        i[3] && (i[2] ? i[0] : i[1]),
      ];

  // ------------------------------------------------------- the arithmetic unit

  /// Level 39 — a 2-bit number times three, in four bits.
  static List<bool> tripleIt(List<bool> i) => _bits(_value(i) * 3, 4);

  /// Level 40 — a 2-bit number plus one, wrapping at four.
  static List<bool> addOne(List<bool> i) => _bits((_value(i) + 1) % 4, 2);

  /// Level 41 — half subtractor over (A, B): DIFF, BORROW.
  static List<bool> halfSubtractor(List<bool> i) => [i[0] != i[1], !i[0] && i[1]];

  /// Level 42 — full subtractor over (A, B, BIN): DIFF, BORROW OUT.
  static List<bool> fullSubtractor(List<bool> i) {
    final difference = (i[0] ? 1 : 0) - (i[1] ? 1 : 0) - (i[2] ? 1 : 0);
    return [difference.isOdd, difference < 0];
  }

  /// Level 43 — two's complement: a 3-bit number negated, wrapping at eight.
  static List<bool> negate3Bit(List<bool> i) => _bits((8 - _value(i)) % 8, 3);

  /// Level 44 — two 2-bit numbers added: CARRY, S1, S0.
  static List<bool> addTwoBit(List<bool> i) =>
      _bits(_value(i.sublist(0, 2)) + _value(i.sublist(2, 4)), 3);

  /// Level 45 — two 2-bit numbers multiplied, in four bits.
  static List<bool> multiplyTwoBit(List<bool> i) =>
      _bits(_value(i.sublist(0, 2)) * _value(i.sublist(2, 4)), 4);

  // -------------------------------------------------------------- black boxes

  /// Level 46 — hidden: A chooses which of the other two gets through.
  static List<bool> latchKey(List<bool> i) => [i[0] ? i[1] : i[2]];

  /// Level 47 — hidden: the losing side of a three-way vote.
  static List<bool> minority(List<bool> i) => [_count(i) < 2];

  /// Level 48 — hidden: neighbouring bits compared, the Gray-code step.
  static List<bool> grayStep(List<bool> i) => [i[0] != i[1], i[1] != i[2]];

  /// Level 49 — hidden: at least two of four.
  static List<bool> threshold(List<bool> i) => [_count(i) >= 2];

  /// Level 50 — hidden: one exact 4-bit code, 1001, and nothing else.
  static List<bool> combinationLock(List<bool> i) => [_value(i) == 9];

  // ---------------------------------------------------------- under constraint

  /// Level 56 — A flipped by whether B and C are both high.
  static List<bool> tightFit(List<bool> i) => [i[0] != (i[1] && i[2])];

  // ------------------------------------------------------------ the workshop

  /// Level 57 — the top bar of a seven-segment digit, for BCD 0-9. Codes
  /// 10-15 are not digits, so the display stays dark.
  static List<bool> segmentTop(List<bool> i) =>
      [const [0, 2, 3, 5, 6, 7, 8, 9].contains(_value(i))];

  /// Level 58 — the two right-hand rails of a seven-segment digit.
  static List<bool> segmentRails(List<bool> i) {
    final digit = _value(i);
    return [
      const [0, 1, 2, 3, 4, 7, 8, 9].contains(digit),
      const [0, 1, 3, 4, 5, 6, 7, 8, 9].contains(digit),
    ];
  }

  /// Level 59 — a 4-bit number that divides by three, zero included.
  static List<bool> divisibleByThree(List<bool> i) => [_value(i) % 3 == 0];

  /// Level 60 — a 4-bit prime.
  static List<bool> prime(List<bool> i) =>
      [const [2, 3, 5, 7, 11, 13].contains(_value(i))];

  /// Level 61 — a 4-bit number inside the window 4..11.
  static List<bool> inRange(List<bool> i) {
    final value = _value(i);
    return [value >= 4 && value <= 11];
  }

  /// Level 62 — (S1, S0, A, B): one output, four operations.
  static List<bool> tinyAlu(List<bool> i) {
    final a = i[2];
    final b = i[3];
    return [
      switch (_value(i.sublist(0, 2))) {
        0 => a && b,
        1 => a || b,
        2 => a != b,
        _ => !(a && b),
      },
    ];
  }

  /// Level 63 — the larger of two 2-bit numbers.
  static List<bool> sorter(List<bool> i) {
    final a = _value(i.sublist(0, 2));
    final b = _value(i.sublist(2, 4));
    return _bits(a > b ? a : b, 2);
  }

  // ----------------------------------------------------------------- helpers

  static int _count(List<bool> bits) => bits.where((b) => b).length;

  /// Reads [bits] as a binary number, first bit most significant.
  static int _value(List<bool> bits) =>
      bits.fold(0, (acc, bit) => (acc << 1) | (bit ? 1 : 0));

  /// Writes [value] as [width] bits, most significant first.
  static List<bool> _bits(int value, int width) => [
        for (var bit = width - 1; bit >= 0; bit--) (value >> bit) & 1 == 1,
      ];

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
    14: invert,
    15: disjunction,
    16: conjunction,
    17: exclusiveOr,
    18: exclusiveOr,
    19: threeWaySwitch,
    20: seatbeltAlarm,
    21: sprinkler,
    22: elevator,
    23: vendingMachine,
    24: trafficCrossing,
    25: safeDeposit,
    26: exactlyOne,
    27: allOrNothing,
    28: countToTwo,
    29: countToFour,
    30: parityOfFour,
    31: exactlyTwo,
    32: atLeastThree,
    33: decoder2To4,
    34: demultiplexer,
    35: gatedPair,
    36: swapOnDemand,
    37: priorityEncoder,
    38: crossbar,
    39: tripleIt,
    40: addOne,
    41: halfSubtractor,
    42: fullSubtractor,
    43: negate3Bit,
    44: addTwoBit,
    45: multiplyTwoBit,
    46: latchKey,
    47: minority,
    48: grayStep,
    49: threshold,
    50: combinationLock,
    51: invert,
    52: disjunction,
    53: exclusiveOr,
    54: selector,
    55: majority,
    56: tightFit,
    57: segmentTop,
    58: segmentRails,
    59: divisibleByThree,
    60: prime,
    61: inRange,
    62: tinyAlu,
    63: sorter,
  };
}
