/// Three-valued (Kleene) logic, so a floating input is first-class rather
/// than silently zero (CLAUDE.md §6.1).
enum Logic {
  low,
  high,

  /// Undefined: an input port with no wire feeding it.
  floating;

  bool get isHigh => this == Logic.high;
  bool get isLow => this == Logic.low;
  bool get isFloating => this == Logic.floating;

  /// `0`, `1`, `X` — used on lamps and in the tester so value never depends
  /// on color alone (CLAUDE.md §16).
  String get glyph => switch (this) {
        Logic.low => '0',
        Logic.high => '1',
        Logic.floating => 'X',
      };

  static Logic fromBool(bool value) => value ? Logic.high : Logic.low;
}
