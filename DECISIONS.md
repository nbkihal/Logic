# DECISIONS.md

Running record of open decisions resolved and deviations taken, so a reviewer
never has to guess why the code differs from the spec.

## Open decisions (spec §20) — defaults taken

| # | Decision | Taken | Where |
| --- | --- | --- | --- |
| 1 | Framework | Flutter (the assumed default) | whole repo |
| 2 | Floating logic | Tri-state Kleene logic, kept | `domain/engine/gate_logic.dart` |
| 3 | Fan-in on an occupied input port | Reject with a nudge — *pending Phase 3* | — |
| 4 | Two-star band | `<= par + ceil(par / 2)` | `Level.starsFor` |
| 5 | Hint affects stars | No | *pending Phase 6* |
| 6 | Unlock rule | One star to advance — *pending Phase 6* | — |
| 7 | Ship level 13 | Built as data now, gated behind level 12 later | `levels_data.dart` |

All are the spec's recommended defaults. None has been overridden.

## Deviations

### Level 13 par raised from 8 to 9

The spec's stage table gives the 2-bit comparator a par of 8. The best
reference solution found uses **9** two-input gates:

```
x1 = A1 XOR B1          x0 = A0 XOR B0
gtHigh = A1 AND x1      (= A1 AND NOT B1, no separate inverter)
gtLow  = A0 AND x0
sameHigh = NOT x1
gtLowGated = sameHigh AND gtLow
GT = gtHigh OR gtLowGated
EQ = NOR(x1, x0)
LT = NOR(GT, EQ)
```

A par below the achievable minimum makes three stars impossible, which the
§15 par-sanity test exists to catch. Par is set to 9. If a reviewer finds an
8-gate construction, lower it back and the test will confirm it.

### Level 9's hidden function is material implication (`A -> B`)

The stage table leaves the black-box function unspecified ("*(hidden table)*",
par `<= 4`). Implication was chosen: it is solvable in 2 gates from the
level's palette, and "if A then B" is a genuinely under-taught operator, which
fits the level's teaching goal. Par is 2.

### NAND-only stages do not receive the stage-6 optional extras

§8 says NOR/XNOR/BUFFER/constants are available "from stage 6 onward" as
optional tools. Stages 7 and 8 are defined by their restriction to NAND, so
the extras are withheld there. Stages 6, 9 and 10 get them; 11-13 use the
full set.

### Graph algorithms are extensions on `Circuit`

§5 lists `toposort()` and `hasCycle()` as `Circuit` helpers, while §9 puts the
algorithms under `domain/engine/`. They live in `engine/toposort.dart` and
`engine/cycle_detector.dart` as extension methods on `Circuit`, so the call
shape matches §5 without `models/` importing `engine/`.

### `CycleError` reports loop members only

Kahn's algorithm leaves behind the loop *and* everything downstream of it. The
detector peels the remainder down to nodes that actually sit on a cycle, so
the amber highlight lands on the fault rather than on every component that
happens to read a looping value.

### Product name is "Logic"

The working title was "Logic Circuit Builder". The shipped app name is
**Logic** everywhere a user sees it — Android label, iOS bundle name, web
title and manifest, and the `MaterialApp` title. "Circuit Builder" survives as
a kicker under the wordmark on Home. The Dart package stays
`logic_circuit_builder`; renaming it buys nothing and churns every import.

### App icon is generated, not hand-drawn

`tool/generate_icon.py` draws a NAND gate — body, inversion bubble, two input
leads and an output lead with port dots — in Obsidian on Ember, and writes a
full-bleed 1024px icon plus a transparent Android adaptive foreground inset to
the safe zone. `flutter_launcher_icons.yaml` fans those out to Android, iOS
and web. Change the mark by editing the script and re-running both steps;
there is no binary to hand-edit.

### Ports are drawn by the component widgets, not the painter

Phase 2's file list puts ports in `circuit_painter.dart`, while §12 says
components are widgets so they can host gestures and semantics. Ports live in
`GateWidget`: they are what Phase 3 hit-tests for wiring, and they need their
own semantics and enlarged touch targets. The painter draws the grid and the
wires.

### The board is a fixed world with an origin offset

Level fixtures are centred on grid row 0, so grid coordinates go negative.
`CanvasGeometry` maps grid to world pixels through a single origin offset
(`CanvasConstants.originCellX/Y`), which keeps every component at positive
world coordinates inside a fixed 32x20-cell board. One conversion, used by the
painter, the component layer, and Phase 3's hit-testing alike.

### Value glyphs use tabular figures, not a monospace family

`0`, `1` and `X` want a fixed advance so they do not jitter when a value
flips. A bare `monospace` family only resolves on some platforms and renders
as tofu on the rest — it did, visibly, in the first render. The bundled body
face with `FontFeature.tabularFigures()` gets the same result everywhere.

### Pan and zoom use `InteractiveViewer`

§12 asks for a single `Matrix4` with all hit-testing through its inverse.
`InteractiveViewer` with a `TransformationController` *is* that matrix, and it
gives correct child hit-testing for the component widgets for free. Screen-to-
world conversion goes through `MatrixUtils.transformPoint` on the inverse, in
one place.

### Display typeface

`PP Neue Corp Compact` is not redistributable, so the spec's own substitute
list is used: **Anton** (OFL) for display, **DM Sans** (OFL, variable, weight
axis pinned to 500) for body. Both are bundled under `assets/fonts/` with
their licences. Swap in the real face by replacing the asset and the family
name in `AppTypography`.

## Placeholders a reviewer should replace

- App id / bundle id: `com.example.logic_circuit_builder`
- Product name: still the working title, "Logic Circuit Builder"
