/// Every placeable thing on the board.
///
/// `input`, `output` and `constant` are not gates in the scoring sense — they
/// are free fixtures (CLAUDE.md §7). Only the Boolean operators count toward
/// the gate budget.
enum GateType {
  /// A user-toggleable source pin.
  input,

  /// An output lamp: consumes a value, produces none.
  output,

  /// A fixed 0 or 1 source.
  constant,

  /// Passthrough.
  buffer,
  not,
  and,
  or,
  nand,
  nor,
  xor,
  xnor;

  /// True for the Boolean operators, i.e. the components that count toward
  /// the gate budget and stars.
  bool get isGate => switch (this) {
        GateType.input || GateType.output || GateType.constant => false,
        _ => true,
      };

  /// A source has an output port and no inputs.
  bool get isSource =>
      this == GateType.input || this == GateType.constant;

  /// How many input ports this type exposes.
  int get inputPortCount => switch (this) {
        GateType.input || GateType.constant => 0,
        GateType.output || GateType.buffer || GateType.not => 1,
        GateType.and ||
        GateType.or ||
        GateType.nand ||
        GateType.nor ||
        GateType.xor ||
        GateType.xnor =>
          2,
      };

  /// Output lamps are sinks; everything else drives a value.
  bool get hasOutputPort => this != GateType.output;

  /// Short label used on the component body and in semantics.
  String get label => switch (this) {
        GateType.input => 'IN',
        GateType.output => 'OUT',
        GateType.constant => 'CONST',
        GateType.buffer => 'BUF',
        GateType.not => 'NOT',
        GateType.and => 'AND',
        GateType.or => 'OR',
        GateType.nand => 'NAND',
        GateType.nor => 'NOR',
        GateType.xor => 'XOR',
        GateType.xnor => 'XNOR',
      };
}
