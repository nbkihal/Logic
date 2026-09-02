/// Which way a port faces.
enum PortDirection { input, output }

/// A connection point on a component.
///
/// An input port accepts at most one wire; an output port may fan out to
/// many (CLAUDE.md §4).
class Port {
  const Port({
    required this.id,
    required this.componentId,
    required this.direction,
    required this.index,
  });

  /// Builds the canonical id for an input port: `"<componentId>:in<index>"`.
  factory Port.input(String componentId, int index) => Port(
        id: inputId(componentId, index),
        componentId: componentId,
        direction: PortDirection.input,
        index: index,
      );

  /// Builds the canonical id for the single output port: `"<componentId>:out"`.
  factory Port.output(String componentId) => Port(
        id: outputId(componentId),
        componentId: componentId,
        direction: PortDirection.output,
        index: 0,
      );

  /// Stable id, e.g. `"c3:in0"`.
  final String id;
  final String componentId;
  final PortDirection direction;

  /// 0-based. Gates number their inputs `in0`, `in1`.
  final int index;

  static String inputId(String componentId, int index) =>
      '$componentId:in$index';

  static String outputId(String componentId) => '$componentId:out';

  bool get isInput => direction == PortDirection.input;
  bool get isOutput => direction == PortDirection.output;

  @override
  bool operator ==(Object other) => other is Port && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Port($id)';
}
