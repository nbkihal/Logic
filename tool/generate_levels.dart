// Regenerates `lib/data/levels/levels_data.dart`.
//
// Every target table in the shipped file is hard-coded (CLAUDE.md §8), but
// hand-typing sixty of them is how a wrong row reaches a player. So the tables
// are expanded here from `ReferenceFunctions` — the same functions the §15
// unit test checks them against — and each level's `par` is measured by
// synthesizing a solution from that level's own palette.
//
//   dart run tool/generate_levels.dart > lib/data/levels/levels_data.dart
//
// Levels 1-13 shipped before this generator existed and keep their
// hand-tuned pars via [_Spec.par]; everything after is measured.

import 'package:logic_circuit_builder/data/levels/reference_functions.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/truth_table.dart';

import '../test/fixtures/synthesis.dart';

const _extras = {
  GateType.nor,
  GateType.xnor,
  GateType.buffer,
  GateType.constant,
};

const _palettes = <String, Set<GateType>>{
  '_notOnly': {GateType.not},
  '_andNot': {GateType.and, GateType.not},
  '_primitives': {GateType.and, GateType.or, GateType.not},
  '_withXor': {GateType.and, GateType.or, GateType.not, GateType.xor},
  '_toolkit': {
    GateType.and,
    GateType.or,
    GateType.not,
    GateType.xor,
    ..._extras,
  },
  '_nandOnly': {GateType.nand},
  '_norOnly': {GateType.nor},
  '_ringSum': {GateType.xor, GateType.and, GateType.constant},
  '_noInverter': {
    GateType.and,
    GateType.or,
    GateType.xor,
    GateType.constant,
  },
  '_fullSet': {
    GateType.not,
    GateType.and,
    GateType.or,
    GateType.nand,
    GateType.nor,
    GateType.xor,
    GateType.xnor,
    GateType.buffer,
    GateType.constant,
  },
};

class _Spec {
  const _Spec({
    required this.id,
    required this.name,
    required this.chapter,
    required this.blurb,
    required this.inputs,
    required this.outputs,
    required this.palette,
    this.par,
    this.hidden = false,
    this.gateLimit,
  });

  final int id;
  final String name;
  final String chapter;
  final String blurb;
  final List<String> inputs;
  final List<String> outputs;
  final String palette;

  /// Hand-tuned par. Null means "measure it".
  final int? par;
  final bool hidden;
  final int? gateLimit;
}

const _chapter1 = 'First Signals';
const _chapter2 = 'Nothing But NAND';
const _chapter3 = 'Deeper Boards';
const _chapter4 = 'The Universal Gates';
const _chapter5 = 'Everyday Logic';
const _chapter6 = 'Counting Bits';
const _chapter7 = 'Choosing and Routing';
const _chapter8 = 'The Arithmetic Unit';
const _chapter9 = 'Detective Work';
const _chapter10 = 'Under Constraint';
const _chapter11 = 'The Grand Workshop';

const _specs = <_Spec>[
  // -------------------------------------------------------------- chapter 1
  _Spec(
    id: 1,
    name: 'Invert It',
    chapter: _chapter1,
    blurb: 'One gate, one job: flip the signal.',
    inputs: ['A'],
    outputs: ['Q'],
    palette: '_notOnly',
    par: 1,
  ),
  _Spec(
    id: 2,
    name: 'Both On',
    chapter: _chapter1,
    blurb: 'Light up only when both switches are on.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_andNot',
    par: 1,
  ),
  _Spec(
    id: 3,
    name: 'Either On',
    chapter: _chapter1,
    blurb: 'One switch is enough this time.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_primitives',
    par: 1,
  ),
  _Spec(
    id: 4,
    name: 'Not Both',
    chapter: _chapter1,
    blurb: 'Chain two gates: invert what AND says.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_andNot',
    par: 2,
  ),
  _Spec(
    id: 5,
    name: 'Odd One Out',
    chapter: _chapter1,
    blurb: 'Exactly one, never both — build XOR from scratch.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_primitives',
    par: 5,
  ),
  _Spec(
    id: 6,
    name: 'Half Adder',
    chapter: _chapter1,
    blurb: 'Add two bits: a sum and a carry.',
    inputs: ['A', 'B'],
    outputs: ['SUM', 'CARRY'],
    palette: '_toolkit',
    par: 2,
  ),
  // -------------------------------------------------------------- chapter 2
  _Spec(
    id: 7,
    name: 'Nothing But NAND',
    chapter: _chapter2,
    blurb: 'One gate type can build them all. Start with AND.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_nandOnly',
    par: 2,
  ),
  _Spec(
    id: 8,
    name: 'NAND Makes OR',
    chapter: _chapter2,
    blurb: 'Still only NAND. Now make OR out of it.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_nandOnly',
    par: 3,
  ),
  // -------------------------------------------------------------- chapter 3
  _Spec(
    id: 9,
    name: 'Black Box',
    chapter: _chapter3,
    blurb: 'The table is hidden. Poke the inputs and work it out.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_toolkit',
    par: 2,
    hidden: true,
  ),
  _Spec(
    id: 10,
    name: 'Majority Rules',
    chapter: _chapter3,
    blurb: 'Three votes in, the winning side out.',
    inputs: ['A', 'B', 'C'],
    outputs: ['Q'],
    palette: '_toolkit',
    par: 4,
  ),
  _Spec(
    id: 11,
    name: 'Full Adder',
    chapter: _chapter3,
    blurb: 'Two bits plus a carry-in. The heart of arithmetic.',
    inputs: ['A', 'B', 'CIN'],
    outputs: ['SUM', 'CARRY'],
    palette: '_fullSet',
    par: 5,
  ),
  _Spec(
    id: 12,
    name: 'The Selector',
    chapter: _chapter3,
    blurb: 'S picks the winner: pass A through, or pass B.',
    inputs: ['A', 'B', 'S'],
    outputs: ['Q'],
    palette: '_fullSet',
    par: 4,
  ),
  _Spec(
    id: 13,
    name: 'Capstone: Compare',
    chapter: _chapter3,
    blurb: 'Two 2-bit numbers in. Greater, equal, or less out.',
    inputs: ['A1', 'A0', 'B1', 'B0'],
    outputs: ['A>B', 'A=B', 'A<B'],
    palette: '_fullSet',
    par: 9,
  ),
  // -------------------------------------------------------------- chapter 4
  _Spec(
    id: 14,
    name: 'Nothing But NOR',
    chapter: _chapter4,
    blurb: 'A second universal gate. It starts by saying no, too.',
    inputs: ['A'],
    outputs: ['Q'],
    palette: '_norOnly',
    par: 1,
  ),
  _Spec(
    id: 15,
    name: 'NOR Makes OR',
    chapter: _chapter4,
    blurb: 'Undo the NOT and plain OR falls straight out.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_norOnly',
  ),
  _Spec(
    id: 16,
    name: 'NOR Makes AND',
    chapter: _chapter4,
    blurb: 'Invert both inputs first, then ask NOR again.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_norOnly',
  ),
  _Spec(
    id: 17,
    name: 'NOR Makes XOR',
    chapter: _chapter4,
    blurb: 'The hardest shape yet from the smallest toolkit.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_norOnly',
  ),
  _Spec(
    id: 18,
    name: 'NAND Makes XOR',
    chapter: _chapter4,
    blurb: 'Same puzzle, the other universal gate. Which comes cheaper?',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_nandOnly',
    // NAND beats NOR here by one gate, but only if you spot the shared term;
    // the synthesizer settles for five, so this par is set by hand.
    par: 4,
  ),
  // -------------------------------------------------------------- chapter 5
  _Spec(
    id: 19,
    name: 'Three-Way Switch',
    chapter: _chapter5,
    blurb: 'A hallway lamp with three doorways: any switch flips it.',
    inputs: ['A', 'B', 'C'],
    outputs: ['LAMP'],
    palette: '_toolkit',
  ),
  _Spec(
    id: 20,
    name: 'Seatbelt Chime',
    chapter: _chapter5,
    blurb: 'Nag only when the seat is taken, the key is in, the belt is not.',
    inputs: ['KEY', 'BELT', 'SEAT'],
    outputs: ['CHIME'],
    palette: '_toolkit',
  ),
  _Spec(
    id: 21,
    name: 'Sprinkler Head',
    chapter: _chapter5,
    blurb: 'Smoke and heat together — or the monthly drill.',
    inputs: ['SMOKE', 'HEAT', 'TEST'],
    outputs: ['SPRAY'],
    palette: '_toolkit',
  ),
  _Spec(
    id: 22,
    name: 'Elevator Call',
    chapter: _chapter5,
    blurb: 'Both buttons at once cancel out, and the doors must be shut.',
    inputs: ['UP', 'DOWN', 'DOORS'],
    outputs: ['MOVE'],
    palette: '_toolkit',
  ),
  _Spec(
    id: 23,
    name: 'Vending Machine',
    chapter: _chapter5,
    blurb: 'Keep the coin only if you can deliver. Otherwise, refund.',
    inputs: ['COIN', 'PICK', 'STOCK'],
    outputs: ['VEND', 'REFUND'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 24,
    name: 'Traffic Crossing',
    chapter: _chapter5,
    blurb: 'Cars flow, people cross, and the night shift changes both.',
    inputs: ['CAR', 'PED', 'NIGHT'],
    outputs: ['GREEN', 'WALK'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 25,
    name: 'Safe Deposit',
    chapter: _chapter5,
    blurb: 'Any two keyholders agree — or the manager overrules them.',
    inputs: ['KEY A', 'KEY B', 'KEY C', 'MGR'],
    outputs: ['OPEN'],
    palette: '_fullSet',
  ),
  // -------------------------------------------------------------- chapter 6
  _Spec(
    id: 26,
    name: 'Exactly One',
    chapter: _chapter6,
    blurb: 'One raised hand is a vote. Two is an argument.',
    inputs: ['A', 'B', 'C'],
    outputs: ['Q'],
    palette: '_withXor',
  ),
  _Spec(
    id: 27,
    name: 'All or Nothing',
    chapter: _chapter6,
    blurb: 'Fire only when all three agree — either way.',
    inputs: ['A', 'B', 'C'],
    outputs: ['Q'],
    palette: '_withXor',
  ),
  _Spec(
    id: 28,
    name: 'Count to Two',
    chapter: _chapter6,
    blurb: 'How many are high? Answer in binary.',
    inputs: ['A', 'B', 'C'],
    outputs: ['C1', 'C0'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 29,
    name: 'Count to Four',
    chapter: _chapter6,
    blurb: 'One bit wider, and now the answer needs three lamps.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['C2', 'C1', 'C0'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 30,
    name: 'Odd Ones Out',
    chapter: _chapter6,
    blurb: 'Four bits in, one parity bit out — the checksum of its day.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['P'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 31,
    name: 'Exactly Two',
    chapter: _chapter6,
    blurb: 'Not one, not three. Exactly two.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['Q'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 32,
    name: 'At Least Three',
    chapter: _chapter6,
    blurb: 'A supermajority of four.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['Q'],
    palette: '_fullSet',
  ),
  // -------------------------------------------------------------- chapter 7
  _Spec(
    id: 33,
    name: 'Four-Way Decoder',
    chapter: _chapter7,
    blurb: 'A 2-bit number points at exactly one of four lamps.',
    inputs: ['A1', 'A0'],
    outputs: ['Y0', 'Y1', 'Y2', 'Y3'],
    palette: '_andNot',
  ),
  _Spec(
    id: 34,
    name: 'Signal Splitter',
    chapter: _chapter7,
    blurb: 'One signal, two paths, one switch to pick between them.',
    inputs: ['D', 'S'],
    outputs: ['Y0', 'Y1'],
    palette: '_toolkit',
  ),
  _Spec(
    id: 35,
    name: 'Gated Pair',
    chapter: _chapter7,
    blurb: 'Two channels held shut until ENABLE says otherwise.',
    inputs: ['A', 'B', 'EN'],
    outputs: ['QA', 'QB'],
    palette: '_toolkit',
  ),
  _Spec(
    id: 36,
    name: 'Swap on Demand',
    chapter: _chapter7,
    blurb: 'Straight through, or crossed over. S decides.',
    inputs: ['A', 'B', 'S'],
    outputs: ['X', 'Y'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 37,
    name: 'Priority Encoder',
    chapter: _chapter7,
    blurb: 'Four requests at once: the highest number wins, and says so.',
    inputs: ['D3', 'D2', 'D1', 'D0'],
    outputs: ['VALID', 'Q1', 'Q0'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 38,
    name: 'The Crossbar',
    chapter: _chapter7,
    blurb: 'Route the pair, then cut power to the whole thing.',
    inputs: ['A', 'B', 'S', 'EN'],
    outputs: ['X', 'Y'],
    palette: '_fullSet',
  ),
  // -------------------------------------------------------------- chapter 8
  _Spec(
    id: 39,
    name: 'Triple It',
    chapter: _chapter8,
    blurb: 'Two bits in, three times as much out.',
    inputs: ['A1', 'A0'],
    outputs: ['P3', 'P2', 'P1', 'P0'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 40,
    name: 'Add One',
    chapter: _chapter8,
    blurb: 'Count up by one, and wrap around at four.',
    inputs: ['A1', 'A0'],
    outputs: ['S1', 'S0'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 41,
    name: 'Half Subtractor',
    chapter: _chapter8,
    blurb: 'Take one bit from another, and mind the borrow.',
    inputs: ['A', 'B'],
    outputs: ['DIFF', 'BORROW'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 42,
    name: 'Full Subtractor',
    chapter: _chapter8,
    blurb: 'Now with a borrow arriving from the column before.',
    inputs: ['A', 'B', 'BIN'],
    outputs: ['DIFF', 'BOUT'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 43,
    name: 'Negate',
    chapter: _chapter8,
    blurb: 'Twos complement: flip every bit, then add one.',
    inputs: ['A2', 'A1', 'A0'],
    outputs: ['N2', 'N1', 'N0'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 44,
    name: 'Two-Bit Adder',
    chapter: _chapter8,
    blurb: 'Two numbers, two bits each. Chain what you already know.',
    inputs: ['A1', 'A0', 'B1', 'B0'],
    outputs: ['CARRY', 'S1', 'S0'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 45,
    name: 'The Multiplier',
    chapter: _chapter8,
    blurb: 'Every product bit is one AND away. The carries are the work.',
    inputs: ['A1', 'A0', 'B1', 'B0'],
    outputs: ['P3', 'P2', 'P1', 'P0'],
    palette: '_fullSet',
  ),
  // -------------------------------------------------------------- chapter 9
  _Spec(
    id: 46,
    name: 'Black Box: Keyholder',
    chapter: _chapter9,
    blurb: 'Poke the inputs. One of the three is quietly in charge.',
    inputs: ['A', 'B', 'C'],
    outputs: ['Q'],
    palette: '_fullSet',
    hidden: true,
  ),
  _Spec(
    id: 47,
    name: 'Black Box: Minority',
    chapter: _chapter9,
    blurb: 'A vote you have counted before. The other side wins.',
    inputs: ['A', 'B', 'C'],
    outputs: ['Q'],
    palette: '_fullSet',
    hidden: true,
  ),
  _Spec(
    id: 48,
    name: 'Black Box: Cipher',
    chapter: _chapter9,
    blurb: 'Two lamps, each watching a different neighbouring pair.',
    inputs: ['A', 'B', 'C'],
    outputs: ['X', 'Y'],
    palette: '_fullSet',
    hidden: true,
  ),
  _Spec(
    id: 49,
    name: 'Black Box: Threshold',
    chapter: _chapter9,
    blurb: 'Sixteen rows hide a counting rule. Find where it tips.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['Q'],
    palette: '_fullSet',
    hidden: true,
  ),
  _Spec(
    id: 50,
    name: 'Black Box: Combination',
    chapter: _chapter9,
    blurb: 'Exactly one code opens it. Sixteen to try.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['OPEN'],
    palette: '_fullSet',
    hidden: true,
  ),
  // ------------------------------------------------------------- chapter 10
  _Spec(
    id: 51,
    name: 'No Inverters',
    chapter: _chapter10,
    blurb: 'Flip a bit with no NOT gate anywhere in the palette.',
    inputs: ['A'],
    outputs: ['Q'],
    palette: '_noInverter',
  ),
  _Spec(
    id: 52,
    name: 'Ring Sum',
    chapter: _chapter10,
    blurb: 'Only XOR and AND. Somehow that is still enough for OR.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_ringSum',
    par: 3,
  ),
  _Spec(
    id: 53,
    name: 'XOR on a Budget',
    chapter: _chapter10,
    blurb: 'You built this one in five. The board now holds four.',
    inputs: ['A', 'B'],
    outputs: ['Q'],
    palette: '_primitives',
    gateLimit: 4,
  ),
  _Spec(
    id: 54,
    name: 'NAND Selector',
    chapter: _chapter10,
    blurb: 'The multiplexer again, from the universal gate alone.',
    inputs: ['A', 'B', 'S'],
    outputs: ['Q'],
    palette: '_nandOnly',
  ),
  _Spec(
    id: 55,
    name: 'NOR Majority',
    chapter: _chapter10,
    blurb: 'Three votes counted with nothing but NOR.',
    inputs: ['A', 'B', 'C'],
    outputs: ['Q'],
    palette: '_norOnly',
  ),
  _Spec(
    id: 56,
    name: 'Tight Fit',
    chapter: _chapter10,
    blurb: 'Two gates. Not one more.',
    inputs: ['A', 'B', 'C'],
    outputs: ['Q'],
    palette: '_fullSet',
    gateLimit: 2,
  ),
  // ------------------------------------------------------------- chapter 11
  _Spec(
    id: 57,
    name: 'Seven Segment: Top Bar',
    chapter: _chapter11,
    blurb: 'Digits 0-9 light the top bar. Codes above nine stay dark.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['SEG A'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 58,
    name: 'Seven Segment: Right Rails',
    chapter: _chapter11,
    blurb: 'Two more segments, and most of their logic is shared.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['SEG B', 'SEG C'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 59,
    name: 'Divisible by Three',
    chapter: _chapter11,
    blurb: 'A four-bit number. Does three go into it?',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['Q'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 60,
    name: 'Prime Detector',
    chapter: _chapter11,
    blurb: 'Sixteen numbers. Six of them are prime.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['Q'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 61,
    name: 'Range Finder',
    chapter: _chapter11,
    blurb: 'Light up inside the window, four through eleven.',
    inputs: ['A', 'B', 'C', 'D'],
    outputs: ['Q'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 62,
    name: 'The Tiny ALU',
    chapter: _chapter11,
    blurb: 'Two select lines, four operations, one board that does them all.',
    inputs: ['S1', 'S0', 'A', 'B'],
    outputs: ['Q'],
    palette: '_fullSet',
  ),
  _Spec(
    id: 63,
    name: 'Capstone: The Sorter',
    chapter: _chapter11,
    blurb: 'Two numbers in. The larger one comes out.',
    inputs: ['A1', 'A0', 'B1', 'B0'],
    outputs: ['M1', 'M0'],
    palette: '_fullSet',
  ),
];

void main() {
  final buffer = StringBuffer()..write(_header);

  for (final spec in _specs) {
    final fn = ReferenceFunctions.byLevelId[spec.id];
    if (fn == null) throw StateError('level ${spec.id} has no reference fn');

    final palette = _palettes[spec.palette];
    if (palette == null) throw StateError('unknown palette ${spec.palette}');

    final rows = ReferenceFunctions.tabulate(spec.inputs.length, fn);
    final table = TruthTable(
      inputNames: spec.inputs,
      outputNames: spec.outputs,
      rows: rows,
    );
    if (!table.isWellFormed) {
      throw StateError('level ${spec.id} table is the wrong shape');
    }

    final par = spec.par ??
        LogicSynthesizer(inputCount: spec.inputs.length, palette: palette)
            .gateCountFor(table);

    buffer
      ..writeln('  Level(')
      ..writeln('    id: ${spec.id},')
      ..writeln("    name: '${spec.name}',")
      ..writeln('    chapter: ${_chapterConst(spec.chapter)},')
      ..writeln("    blurb: '${spec.blurb}',")
      ..writeln('    inputCount: ${spec.inputs.length},')
      ..writeln('    outputCount: ${spec.outputs.length},')
      ..writeln('    palette: ${spec.palette},')
      ..writeln('    par: $par,');
    if (spec.hidden) buffer.writeln('    showTargetTable: false,');
    if (spec.gateLimit != null) {
      buffer.writeln('    gateLimit: ${spec.gateLimit},');
    }
    buffer
      ..writeln('    target: TruthTable(')
      ..writeln('      inputNames: [${_quoted(spec.inputs)}],')
      ..writeln('      outputNames: [${_quoted(spec.outputs)}],')
      ..writeln('      rows: [');
    for (final row in rows) {
      buffer.writeln('        [${row.join(', ')}],');
    }
    buffer
      ..writeln('      ],')
      ..writeln('    ),')
      ..writeln('  ),');
  }

  buffer.writeln('];');
  // ignore: avoid_print
  print(buffer);
}

String _quoted(List<String> names) => names.map((n) => "'$n'").join(', ');

String _chapterConst(String chapter) {
  const names = {
    _chapter1: '_chapter1',
    _chapter2: '_chapter2',
    _chapter3: '_chapter3',
    _chapter4: '_chapter4',
    _chapter5: '_chapter5',
    _chapter6: '_chapter6',
    _chapter7: '_chapter7',
    _chapter8: '_chapter8',
    _chapter9: '_chapter9',
    _chapter10: '_chapter10',
    _chapter11: '_chapter11',
  };
  return names[chapter]!;
}

const _header = '''
// GENERATED by tool/generate_levels.dart — edit that file, not this one.
//
//   dart run tool/generate_levels.dart > lib/data/levels/levels_data.dart
//
// Every target table below is expanded from `ReferenceFunctions`, and every
// par is the gate count of a solution synthesized from that level's own
// palette, so no stage can ship with an impossible target or an impossible
// par (CLAUDE.md §15).

import '../../domain/models/gate_type.dart';
import '../../domain/models/level.dart';
import '../../domain/models/truth_table.dart';

/// The optional tools offered from stage 6 onward: they widen the solution
/// space and reward experimentation without being required by any target
/// (CLAUDE.md §8). Withheld from the single-gate stages, whose whole point is
/// the restriction.
const _extras = {
  GateType.nor,
  GateType.xnor,
  GateType.buffer,
  GateType.constant,
};

const _notOnly = {GateType.not};
const _andNot = {GateType.and, GateType.not};
const _primitives = {GateType.and, GateType.or, GateType.not};
const _withXor = {GateType.and, GateType.or, GateType.not, GateType.xor};
const _toolkit = {..._withXor, ..._extras};
const _nandOnly = {GateType.nand};
const _norOnly = {GateType.nor};

/// XOR, AND and a constant: the ring-sum basis, functionally complete and
/// nothing like the usual one.
const _ringSum = {GateType.xor, GateType.and, GateType.constant};

/// Everything monotone, plus XOR and a constant — inversion has to be built.
const _noInverter = {
  GateType.and,
  GateType.or,
  GateType.xor,
  GateType.constant,
};

const _fullSet = {
  GateType.not,
  GateType.and,
  GateType.or,
  GateType.nand,
  GateType.nor,
  GateType.xor,
  GateType.xnor,
  GateType.buffer,
  GateType.constant,
};

const _chapter1 = 'First Signals';
const _chapter2 = 'Nothing But NAND';
const _chapter3 = 'Deeper Boards';
const _chapter4 = 'The Universal Gates';
const _chapter5 = 'Everyday Logic';
const _chapter6 = 'Counting Bits';
const _chapter7 = 'Choosing and Routing';
const _chapter8 = 'The Arithmetic Unit';
const _chapter9 = 'Detective Work';
const _chapter10 = 'Under Constraint';
const _chapter11 = 'The Grand Workshop';

/// The hand-designed stages, in play order, grouped into chapters.
///
/// Difficulty moves one lever at a time within a chapter — a new gate, one
/// more input, one more output, or a new challenge type — and resets when a
/// new chapter changes the subject.
const List<Level> kLevels = [
''';
