import 'port.dart';

/// A connection from one output port to one input port.
class Wire {
  const Wire({required this.id, required this.from, required this.to});

  final String id;

  /// Must be an output port.
  final Port from;

  /// Must be an input port.
  final Port to;

  /// A wire is well-formed only if it runs output -> input.
  bool get isWellFormed => from.isOutput && to.isInput;

  String get fromComponentId => from.componentId;
  String get toComponentId => to.componentId;

  @override
  bool operator ==(Object other) =>
      other is Wire && other.id == id && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(id, from, to);

  @override
  String toString() => 'Wire($id: ${from.id} -> ${to.id})';
}
