import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/data/levels/levels_data.dart';
import 'package:logic_circuit_builder/domain/engine/win_checker.dart';

import 'synthesis.dart';

void main() {
  for (final level in kLevels) {
    test('synthesizes level ${level.id} — ${level.name}', () {
      final synth = LogicSynthesizer.forLevel(level);
      final circuit = synth.circuitFor(level);
      // ignore: avoid_print
      print('level ${level.id} ${level.name}: '
          '${circuit.gateCount} gates (par ${level.par})');
      expect(WinChecker.isSolved(circuit, level), isTrue);
    });
  }
}
