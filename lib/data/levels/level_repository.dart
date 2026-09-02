import '../../domain/models/circuit.dart';
import '../../domain/models/component.dart';
import '../../domain/models/gate_type.dart';
import '../../domain/models/level.dart';
import 'levels_data.dart';

/// Read-only access to the shipped stages.
class LevelRepository {
  const LevelRepository([this._levels = kLevels]);

  final List<Level> _levels;

  List<Level> get all => List.unmodifiable(_levels);

  int get count => _levels.length;

  Level? byId(int id) {
    for (final level in _levels) {
      if (level.id == id) return level;
    }
    return null;
  }

  /// The level after [id], or null at the end of the arc.
  Level? next(int id) {
    final index = _levels.indexWhere((l) => l.id == id);
    if (index < 0 || index + 1 >= _levels.length) return null;
    return _levels[index + 1];
  }
}

/// Builds a level's starting board: its input pins on the left, its output
/// lamps on the right, and nothing else. `Reset` returns to exactly this.
///
/// Ids are `in_0..in_n` / `out_0..out_n` so that lexicographic component
/// ordering matches truth-table column order (see [Circuit]).
abstract final class LevelFixtures {
  /// Horizontal grid column for the input pins.
  static const inputColumn = 0;

  /// Horizontal grid column for the output lamps.
  static const outputColumn = 18;

  /// Vertical grid spacing between adjacent fixtures.
  static const rowSpacing = 4;

  static String inputId(int index) => 'in_$index';
  static String outputId(int index) => 'out_$index';

  static Circuit startingCircuit(Level level) {
    final components = <String, Component>{};

    for (var i = 0; i < level.inputCount; i++) {
      final id = inputId(i);
      components[id] = Component(
        id: id,
        type: GateType.input,
        gridX: inputColumn,
        gridY: _row(i, level.inputCount),
      );
    }
    for (var i = 0; i < level.outputCount; i++) {
      final id = outputId(i);
      components[id] = Component(
        id: id,
        type: GateType.output,
        gridX: outputColumn,
        gridY: _row(i, level.outputCount),
      );
    }

    return Circuit(components: components, wires: const {});
  }

  /// Centers a column of [count] fixtures around grid row 0.
  static int _row(int index, int count) =>
      ((index - (count - 1) / 2) * rowSpacing).round();
}
