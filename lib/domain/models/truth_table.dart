/// A target specification: for every input combination, the required output
/// values.
///
/// Row ordering: combination `i` runs `0 .. 2^inputCount - 1`, with the first
/// input name as the **most-significant bit**. This convention is shared by
/// the engine and the tester UI (CLAUDE.md §5).
class TruthTable {
  const TruthTable({
    required this.inputNames,
    required this.outputNames,
    required this.rows,
  });

  final List<String> inputNames;
  final List<String> outputNames;

  /// `rows[i]` holds the expected outputs for input combination `i`.
  final List<List<bool>> rows;

  int get inputCount => inputNames.length;
  int get outputCount => outputNames.length;
  int get rowCount => 1 << inputCount;

  /// True when the table is the right shape for its declared inputs/outputs.
  bool get isWellFormed =>
      rows.length == rowCount &&
      rows.every((r) => r.length == outputCount);

  /// Decodes combination [index] into per-input booleans, first input first
  /// (most-significant bit first).
  List<bool> inputsAt(int index) => List<bool>.generate(
        inputCount,
        (bit) => (index >> (inputCount - 1 - bit)) & 1 == 1,
        growable: false,
      );

  List<bool> outputsAt(int index) => rows[index];

  @override
  bool operator ==(Object other) {
    if (other is! TruthTable) return false;
    if (other.inputNames.length != inputNames.length ||
        other.outputNames.length != outputNames.length ||
        other.rows.length != rows.length) {
      return false;
    }
    for (var i = 0; i < inputNames.length; i++) {
      if (other.inputNames[i] != inputNames[i]) return false;
    }
    for (var i = 0; i < outputNames.length; i++) {
      if (other.outputNames[i] != outputNames[i]) return false;
    }
    for (var i = 0; i < rows.length; i++) {
      if (other.rows[i].length != rows[i].length) return false;
      for (var j = 0; j < rows[i].length; j++) {
        if (other.rows[i][j] != rows[i][j]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(inputNames),
        Object.hashAll(outputNames),
        Object.hashAll(rows.map(Object.hashAll)),
      );

  @override
  String toString() {
    final header = '${inputNames.join(' ')} | ${outputNames.join(' ')}';
    final body = [
      for (var i = 0; i < rows.length; i++)
        '${inputsAt(i).map((b) => b ? 1 : 0).join(' ')} | '
            '${rows[i].map((b) => b ? 1 : 0).join(' ')}',
    ].join('\n');
    return '$header\n$body';
  }
}
