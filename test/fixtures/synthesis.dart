import 'package:logic_circuit_builder/domain/models/circuit.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/level.dart';
import 'package:logic_circuit_builder/domain/models/port.dart';
import 'package:logic_circuit_builder/domain/models/truth_table.dart';

import 'circuit_builder.dart';

/// A small logic synthesizer, used by the test fixtures.
///
/// Hand-writing a reference circuit for every stage stops scaling somewhere
/// around a dozen levels, so from stage 14 on the reference solution is
/// derived instead: minimize each output, express it over {NOT, AND, OR, XOR},
/// then *lower* that expression onto whatever gates the level actually offers
/// (NAND-only levels get the universal NAND constructions, NOR-only levels the
/// NOR ones). Everything is hash-consed, so a subexpression shared between two
/// outputs is built once.
///
/// The result backs two §15 guardrails at once: it proves each level is
/// solvable with its own palette, and its gate count is the number `par` is
/// set from.
///
/// Functions are bitmasks over truth-table rows: bit `r` is the output for
/// input combination `r`, first input as MSB — the same convention as
/// `TruthTable` and `ReferenceFunctions.tabulate`.
class LogicSynthesizer {
  LogicSynthesizer({required this.inputCount, required this.palette});

  factory LogicSynthesizer.forLevel(Level level) => LogicSynthesizer(
        inputCount: level.inputCount,
        palette: level.palette,
      );

  final int inputCount;
  final Set<GateType> palette;

  late final int _rowCount = 1 << inputCount;
  late final int _full = (1 << _rowCount) - 1;

  final Map<int, _Node> _bestCache = {};
  final Set<int> _inProgress = {};
  final Map<String, _Node> _lowered = {};

  /// Gate keys already committed by an earlier output column.
  final Set<String> _built = {};

  /// Synthesis is stateful (see [_built]), so it runs once per instance.
  List<_Node>? _rootsCache;

  /// Rows where input [i] is high.
  int _varMask(int i) {
    final bit = 1 << (inputCount - 1 - i);
    var mask = 0;
    for (var r = 0; r < _rowCount; r++) {
      if (r & bit != 0) mask |= 1 << r;
    }
    return mask;
  }

  /// Column [output] of [table], as a row bitmask.
  int functionOf(TruthTable table, int output) {
    var mask = 0;
    for (var r = 0; r < table.rowCount; r++) {
      if (table.rows[r][output]) mask |= 1 << r;
    }
    return mask;
  }

  // ---------------------------------------------------------------- search

  /// The cheapest expression found for [f], in the ideal {NOT, AND, OR, XOR}
  /// basis. Cost is measured *after* lowering, so the search already knows
  /// that e.g. an XOR is expensive on a NAND-only board.
  _Node _best(int f) {
    final cached = _bestCache[f];
    if (cached != null) return cached;

    if (f == 0) return _Node.konst(false);
    if (f == _full) return _Node.konst(true);
    for (var i = 0; i < inputCount; i++) {
      if (f == _varMask(i)) return _Node.input(i);
      if (f == (~_varMask(i) & _full)) return _Node.not(_Node.input(i));
    }

    _inProgress.add(f);
    final candidates = <_Node>[];

    for (var i = 0; i < inputCount; i++) {
      final v = _varMask(i);
      final nv = ~v & _full;
      final low = _cofactor(f, i, high: false);
      final high = _cofactor(f, i, high: true);
      // f ignores this input — splitting on it would just re-derive f.
      if (low == high) continue;

      // f = xi XOR g: flipping xi always flips the output.
      if (low == (~high & _full)) {
        candidates.add(_Node.xor(_Node.input(i), _best(low)));
      }
      // f = xi AND g, NOT xi AND g, xi OR g, NOT xi OR g.
      if (f & nv == 0) candidates.add(_Node.and(_Node.input(i), _best(high)));
      if (f & v == 0) {
        candidates.add(_Node.and(_Node.not(_Node.input(i)), _best(low)));
      }
      if (f & v == v) candidates.add(_Node.or(_Node.input(i), _best(low)));
      if (f & nv == nv) {
        candidates.add(_Node.or(_Node.not(_Node.input(i)), _best(high)));
      }

      // Factored splits. When one cofactor implies the other, the mux
      // collapses and the shared part is built once — this is what turns
      // AB + AC + BC into AB + C(A+B).
      if (low & ~high & _full == 0) {
        final g = _best(high);
        final h = _best(low);
        candidates
          ..add(_Node.or(_Node.and(_Node.input(i), g), h))
          ..add(_Node.and(_Node.or(_Node.input(i), h), g));
      }
      if (high & ~low & _full == 0) {
        final g = _best(low);
        final h = _best(high);
        candidates
          ..add(_Node.or(_Node.and(_Node.not(_Node.input(i)), g), h))
          ..add(_Node.and(_Node.or(_Node.not(_Node.input(i)), h), g));
      }
    }

    candidates.add(_sumOfProducts(f));

    final complement = ~f & _full;
    if (!_inProgress.contains(complement)) {
      candidates.add(_Node.not(_best(complement)));
    }

    _inProgress.remove(f);

    var best = candidates.first;
    var bestCost = _cost(best);
    for (final candidate in candidates.skip(1)) {
      final cost = _cost(candidate);
      if (cost < bestCost) {
        best = candidate;
        bestCost = cost;
      }
    }
    return _bestCache[f] = best;
  }

  /// [f] with input [i] pinned high or low, as a function that ignores [i].
  int _cofactor(int f, int i, {required bool high}) {
    final bit = 1 << (inputCount - 1 - i);
    var g = 0;
    for (var r = 0; r < _rowCount; r++) {
      final source = high ? (r | bit) : (r & ~bit);
      if (f >> source & 1 == 1) g |= 1 << r;
    }
    return g;
  }

  /// Minimized sum of products: Quine-McCluskey primes, greedily covered.
  _Node _sumOfProducts(int f) {
    final minterms = [
      for (var r = 0; r < _rowCount; r++)
        if (f >> r & 1 == 1) r,
    ];
    final primes = _primeImplicants(minterms);
    final cover = _greedyCover(primes, minterms);

    return _reduce([for (final prime in cover) _termNode(prime)], _Node.or);
  }

  /// The AND of one implicant's literals.
  _Node _termNode(_Implicant implicant) {
    final literals = <_Node>[];
    for (var i = 0; i < inputCount; i++) {
      final bit = 1 << (inputCount - 1 - i);
      if (implicant.mask & bit != 0) continue; // don't care
      final node = _Node.input(i);
      literals.add(implicant.bits & bit != 0 ? node : _Node.not(node));
    }
    if (literals.isEmpty) return _Node.konst(true);
    return _reduce(literals, _Node.and);
  }

  List<_Implicant> _primeImplicants(List<int> minterms) {
    if (minterms.isEmpty) return const [];

    var current = {for (final m in minterms) _Implicant(m, 0)};
    final primes = <_Implicant>{};

    while (current.isNotEmpty) {
      final next = <_Implicant>{};
      final merged = <_Implicant>{};

      final list = current.toList();
      for (var a = 0; a < list.length; a++) {
        for (var b = a + 1; b < list.length; b++) {
          final x = list[a];
          final y = list[b];
          if (x.mask != y.mask) continue;
          final diff = x.bits ^ y.bits;
          if (diff == 0 || diff & (diff - 1) != 0) continue; // not one bit
          next.add(_Implicant(x.bits & ~diff, x.mask | diff));
          merged
            ..add(x)
            ..add(y);
        }
      }
      primes.addAll(current.where((c) => !merged.contains(c)));
      current = next;
    }
    return primes.toList();
  }

  /// Essential primes first, then whichever prime covers the most of what is
  /// left. Not provably minimal, but tight enough to set a fair par.
  List<_Implicant> _greedyCover(List<_Implicant> primes, List<int> minterms) {
    final covers = {
      for (final prime in primes) prime: _covered(prime, minterms),
    };
    final remaining = minterms.toSet();
    final chosen = <_Implicant>[];

    for (final minterm in minterms) {
      final owners = primes.where((p) => covers[p]!.contains(minterm)).toList();
      if (owners.length == 1 && !chosen.contains(owners.single)) {
        chosen.add(owners.single);
        remaining.removeAll(covers[owners.single]!);
      }
    }

    while (remaining.isNotEmpty) {
      _Implicant? pick;
      var picked = 0;
      for (final prime in primes) {
        if (chosen.contains(prime)) continue;
        final gain = covers[prime]!.where(remaining.contains).length;
        if (gain > picked) {
          picked = gain;
          pick = prime;
        }
      }
      if (pick == null) break;
      chosen.add(pick);
      remaining.removeAll(covers[pick]!);
    }
    return chosen;
  }

  Set<int> _covered(_Implicant implicant, List<int> minterms) => {
        for (final m in minterms)
          if (m & ~implicant.mask == implicant.bits) m,
      };

  _Node _reduce(List<_Node> nodes, _Node Function(_Node, _Node) combine) {
    final sorted = [...nodes]..sort((a, b) => a.key.compareTo(b.key));
    return sorted.reduce(combine);
  }

  // --------------------------------------------------------------- lowering

  /// Rewrites an ideal-basis node into gates this level actually offers.
  _Node lower(_Node node) {
    final cached = _lowered[node.key];
    if (cached != null) return cached;

    final _Node result;
    switch (node.kind) {
      case _Kind.input:
      case _Kind.konst:
        result = node;
      case _Kind.not:
        result = _lowerNot(lower(node.a!));
      case _Kind.and:
        result = _lowerAnd(lower(node.a!), lower(node.b!));
      case _Kind.or:
        result = _lowerOr(lower(node.a!), lower(node.b!));
      case _Kind.xor:
        result = _lowerXor(lower(node.a!), lower(node.b!));
      default:
        throw StateError('unexpected ideal node ${node.kind}');
    }
    return _lowered[node.key] = result;
  }

  _Node _lowerNot(_Node x) {
    // Two inversions in a row cancel — the cheapest gate is the one you skip.
    if (x.kind == _Kind.not) return x.a!;
    if (palette.contains(GateType.not)) return _Node.gate(_Kind.not, x);
    if (palette.contains(GateType.nand)) return _Node.gate(_Kind.nand, x, x);
    if (palette.contains(GateType.nor)) return _Node.gate(_Kind.nor, x, x);
    if (palette.contains(GateType.xnor) &&
        palette.contains(GateType.constant)) {
      return _Node.gate(_Kind.xnor, x, _Node.konst(false));
    }
    if (palette.contains(GateType.xor) && palette.contains(GateType.constant)) {
      return _Node.gate(_Kind.xor, x, _Node.konst(true));
    }
    throw StateError('palette $palette cannot invert');
  }

  _Node _lowerAnd(_Node a, _Node b) {
    if (palette.contains(GateType.and)) return _Node.gate(_Kind.and, a, b);
    if (palette.contains(GateType.nand)) {
      return _lowerNot(_Node.gate(_Kind.nand, a, b));
    }
    if (palette.contains(GateType.nor)) {
      return _Node.gate(_Kind.nor, _lowerNot(a), _lowerNot(b));
    }
    if (palette.contains(GateType.or)) {
      return _lowerNot(_Node.gate(_Kind.or, _lowerNot(a), _lowerNot(b)));
    }
    throw StateError('palette $palette cannot conjoin');
  }

  _Node _lowerOr(_Node a, _Node b) {
    if (palette.contains(GateType.or)) return _Node.gate(_Kind.or, a, b);
    if (palette.contains(GateType.nor)) {
      return _lowerNot(_Node.gate(_Kind.nor, a, b));
    }
    if (palette.contains(GateType.nand)) {
      return _Node.gate(_Kind.nand, _lowerNot(a), _lowerNot(b));
    }
    if (palette.contains(GateType.and)) {
      return _lowerNot(_Node.gate(_Kind.and, _lowerNot(a), _lowerNot(b)));
    }
    throw StateError('palette $palette cannot disjoin');
  }

  _Node _lowerXor(_Node a, _Node b) {
    if (palette.contains(GateType.xor)) return _Node.gate(_Kind.xor, a, b);
    if (palette.contains(GateType.xnor)) {
      return _lowerNot(_Node.gate(_Kind.xnor, a, b));
    }
    // (A OR B) AND NOT(A AND B) — the classic build-from-primitives shape.
    return _lowerAnd(_lowerOr(a, b), _lowerNot(_lowerAnd(a, b)));
  }

  /// What [node] would add to the board: gates in its lowered graph that are
  /// not already standing from an earlier output. Costing reuse this way is
  /// why a multi-output level shares its subcircuits instead of rebuilding
  /// them per lamp.
  int _cost(_Node node) {
    final scratch = LogicSynthesizer(inputCount: inputCount, palette: palette);
    return _gatesOf([scratch.lower(node)])
        .where((gate) => !_built.contains(gate.key))
        .length;
  }

  /// Every gate node reachable from [roots], deduplicated by identity — so a
  /// shared subexpression is counted once, exactly as a player would build it.
  List<_Node> _gatesOf(List<_Node> roots) {
    final seen = <String, _Node>{};
    void walk(_Node node) {
      if (seen.containsKey(node.key)) return;
      if (node.kind != _Kind.input && node.kind != _Kind.konst) {
        seen[node.key] = node;
      }
      if (node.a != null) walk(node.a!);
      if (node.b != null) walk(node.b!);
    }

    for (final root in roots) {
      walk(root);
    }
    return seen.values.toList();
  }

  // ----------------------------------------------------------------- output

  /// One lowered expression per output column of [table], synthesized left to
  /// right so each column can lean on the gates the previous ones put up.
  List<_Node> _roots(TruthTable table) {
    final done = _rootsCache;
    if (done != null) return done;

    // A first pass only lets a later output reuse an earlier one's gates.
    // Feeding the whole board back in and going again lets the earliest
    // output reuse the last one's too, which is where multi-output stages
    // find their real savings. Each pass is measured for real, so a pass
    // that guesses badly is simply discarded.
    var best = <_Node>[];
    var bestCount = 1 << 30;
    final assumed = <String>{};

    for (var pass = 0; pass < 3; pass++) {
      _built
        ..clear()
        ..addAll(assumed);
      _bestCache.clear();

      final roots = <_Node>[];
      for (var out = 0; out < table.outputNames.length; out++) {
        final root = lower(_best(functionOf(table, out)));
        roots.add(root);
        _built.addAll(_gatesOf([root]).map((gate) => gate.key));
        // Costs changed now that more of the board is standing, so the
        // cached choices are stale.
        _bestCache.clear();
      }

      final gates = _gatesOf(roots);
      if (gates.length < bestCount) {
        bestCount = gates.length;
        best = roots;
      }
      assumed
        ..clear()
        ..addAll(gates.map((gate) => gate.key));
    }
    return _rootsCache = best;
  }

  /// Gate count of the synthesized solution — the number `par` is set from.
  int gateCountFor(TruthTable table) => _gatesOf(_roots(table)).length;

  /// A circuit that solves [level], built only from its palette.
  Circuit circuitFor(Level level) {
    final roots = _roots(level.target);
    final builder = CircuitBuilder.forLevel(level);
    final handles = <String, GateHandle>{};

    // Place operands before the gates that read them, so wiring can assume
    // every handle already exists.
    void place(_Node node) {
      if (handles.containsKey(node.key) || node.kind == _Kind.input) return;
      if (node.kind == _Kind.konst) {
        handles[node.key] = builder.constant(value: node.value);
        return;
      }
      if (node.a != null) place(node.a!);
      if (node.b != null) place(node.b!);
      handles[node.key] = builder.gate(node.gateType);
    }

    for (final root in roots) {
      place(root);
    }

    // A node's driving port: an input pin's own output, or its gate's output.
    Port portOf(_Node node) => node.kind == _Kind.input
        ? builder.input(node.index)
        : handles[node.key]!.out;

    for (final node in _gatesOf(roots)) {
      final operands = node.b == null ? [node.a!] : [node.a!, node.b!];
      for (var i = 0; i < operands.length; i++) {
        builder.wire(portOf(operands[i]), handles[node.key]!.at(i));
      }
    }
    for (var out = 0; out < roots.length; out++) {
      builder.wire(portOf(roots[out]), builder.lamp(out));
    }
    return builder.build();
  }
}

enum _Kind { input, konst, not, and, or, nand, nor, xor, xnor }

/// A hash-consed expression node: two nodes with the same shape are the same
/// object, which is what makes a shared subexpression cost one gate, not two.
class _Node {
  _Node._(
    this.kind,
    this.key, {
    this.index = 0,
    this.value = false,
    this.a,
    this.b,
  });

  factory _Node.input(int index) =>
      _intern('i$index', () => _Node._(_Kind.input, 'i$index', index: index));

  factory _Node.konst(bool value) => _intern(
        'k$value',
        () => _Node._(_Kind.konst, 'k$value', value: value),
      );

  factory _Node.not(_Node a) => _Node.gate(_Kind.not, a);
  factory _Node.and(_Node a, _Node b) => _Node.gate(_Kind.and, a, b);
  factory _Node.or(_Node a, _Node b) => _Node.gate(_Kind.or, a, b);
  factory _Node.xor(_Node a, _Node b) => _Node.gate(_Kind.xor, a, b);

  factory _Node.gate(_Kind kind, _Node a, [_Node? b]) {
    var left = a;
    var right = b;
    // Commutative gates get a canonical operand order, so `and(x, y)` and
    // `and(y, x)` intern to one node.
    if (right != null && left.key.compareTo(right.key) > 0) {
      final swap = left;
      left = right;
      right = swap;
    }
    final tail = right == null ? '' : ',${right.key}';
    final key = '${kind.name}(${left.key}$tail)';
    return _intern(key, () => _Node._(kind, key, a: left, b: right));
  }

  static final Map<String, _Node> _interned = {};

  static _Node _intern(String key, _Node Function() create) =>
      _interned.putIfAbsent(key, create);

  final _Kind kind;
  final String key;
  final int index;
  final bool value;
  final _Node? a;
  final _Node? b;

  GateType get gateType => switch (kind) {
        _Kind.not => GateType.not,
        _Kind.and => GateType.and,
        _Kind.or => GateType.or,
        _Kind.nand => GateType.nand,
        _Kind.nor => GateType.nor,
        _Kind.xor => GateType.xor,
        _Kind.xnor => GateType.xnor,
        _Kind.konst => GateType.constant,
        _Kind.input => GateType.input,
      };

  @override
  String toString() => key;
}

/// A cube of the Boolean space: [bits] holds the fixed literal values and
/// [mask] marks the don't-care positions.
class _Implicant {
  const _Implicant(this.bits, this.mask);

  final int bits;
  final int mask;

  @override
  bool operator ==(Object other) =>
      other is _Implicant && other.bits == bits && other.mask == mask;

  @override
  int get hashCode => Object.hash(bits, mask);
}
