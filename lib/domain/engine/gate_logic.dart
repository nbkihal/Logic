import '../models/gate_type.dart';
import '../models/logic.dart';

/// Three-valued gate evaluation (CLAUDE.md §6.1).
///
/// The rule is "a dominating value wins": `AND` with a `0` is `0` even when
/// the other input floats, because no value of the floating input could
/// change the result. That is a small but real teaching detail.
abstract final class GateLogic {
  /// Evaluates [type] over [inputs], which must be in port-index order.
  ///
  /// Sources ([GateType.input], [GateType.constant]) do not go through here —
  /// the simulator seeds their values directly.
  static Logic evaluate(GateType type, List<Logic> inputs) => switch (type) {
        GateType.buffer || GateType.output => _first(inputs),
        GateType.not => not(_first(inputs)),
        GateType.and => and(inputs),
        GateType.or => or(inputs),
        GateType.nand => not(and(inputs)),
        GateType.nor => not(or(inputs)),
        GateType.xor => xor(inputs),
        GateType.xnor => not(xor(inputs)),
        GateType.input || GateType.constant => Logic.floating,
      };

  static Logic _first(List<Logic> inputs) =>
      inputs.isEmpty ? Logic.floating : inputs.first;

  static Logic not(Logic a) => switch (a) {
        Logic.low => Logic.high,
        Logic.high => Logic.low,
        Logic.floating => Logic.floating,
      };

  /// Any `0` forces `0`; otherwise any `X` yields `X`; otherwise `1`.
  static Logic and(List<Logic> inputs) {
    if (inputs.isEmpty) return Logic.floating;
    if (inputs.any((v) => v.isLow)) return Logic.low;
    if (inputs.any((v) => v.isFloating)) return Logic.floating;
    return Logic.high;
  }

  /// Any `1` forces `1`; otherwise any `X` yields `X`; otherwise `0`.
  static Logic or(List<Logic> inputs) {
    if (inputs.isEmpty) return Logic.floating;
    if (inputs.any((v) => v.isHigh)) return Logic.high;
    if (inputs.any((v) => v.isFloating)) return Logic.floating;
    return Logic.low;
  }

  /// Undefined if any input floats; otherwise the parity of the highs.
  static Logic xor(List<Logic> inputs) {
    if (inputs.isEmpty) return Logic.floating;
    if (inputs.any((v) => v.isFloating)) return Logic.floating;
    final highs = inputs.where((v) => v.isHigh).length;
    return highs.isOdd ? Logic.high : Logic.low;
  }
}
