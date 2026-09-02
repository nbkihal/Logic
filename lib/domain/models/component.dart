import 'gate_type.dart';
import 'port.dart';

/// Anything placeable on the board: a gate, an input pin, an output lamp,
/// or a constant.
///
/// Position is in *logical grid* coordinates. Pixel mapping lives entirely in
/// the presentation layer (CLAUDE.md §5).
class Component {
  const Component({
    required this.id,
    required this.type,
    required this.gridX,
    required this.gridY,
    this.inputValue = false,
    this.constantValue = false,
  });

  final String id;
  final GateType type;
  final int gridX;
  final int gridY;

  /// Toggle state. Only meaningful for [GateType.input].
  final bool inputValue;

  /// Only meaningful for [GateType.constant].
  final bool constantValue;

  int get inputPortCount => type.inputPortCount;

  bool get hasOutputPort => type.hasOutputPort;

  /// Counts toward the gate budget and star scoring.
  bool get countsAsGate => type.isGate;

  /// Input ports in index order.
  List<Port> get inputPorts => List<Port>.generate(
        inputPortCount,
        (i) => Port.input(id, i),
        growable: false,
      );

  /// The single output port, or null for an output lamp.
  Port? get outputPort => hasOutputPort ? Port.output(id) : null;

  Component copyWith({
    int? gridX,
    int? gridY,
    bool? inputValue,
    bool? constantValue,
  }) =>
      Component(
        id: id,
        type: type,
        gridX: gridX ?? this.gridX,
        gridY: gridY ?? this.gridY,
        inputValue: inputValue ?? this.inputValue,
        constantValue: constantValue ?? this.constantValue,
      );

  @override
  bool operator ==(Object other) =>
      other is Component &&
      other.id == id &&
      other.type == type &&
      other.gridX == gridX &&
      other.gridY == gridY &&
      other.inputValue == inputValue &&
      other.constantValue == constantValue;

  @override
  int get hashCode =>
      Object.hash(id, type, gridX, gridY, inputValue, constantValue);

  @override
  String toString() => 'Component($id, ${type.name}, $gridX,$gridY)';
}
