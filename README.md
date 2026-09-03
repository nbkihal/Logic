# Logic

An educational Boolean-logic puzzle game. Drag logic gates onto a board, wire
them together, and make the outputs match a target truth table — from a single
NOT gate up to a two-bit multiplier.

Sixty-three stages in eleven chapters: the primitive gates, universality from
NAND and from NOR alone, everyday wiring puzzles (seatbelt chimes, lifts, a
bank vault), bit counting, decoders and encoders, arithmetic, five black boxes
to reverse-engineer, stages under a hard gate budget or a deliberately
crippled palette, and a workshop of seven-segment drivers, number theory and
a tiny ALU.

Flutter, one codebase, targeting Android, iOS and Web.

## Status

Built in phases, each behind a review gate.

| Phase | Scope | State |
| --- | --- | --- |
| 0 | Setup, theme tokens, routing shell | done |
| 1 | Domain models + simulation engine (no UI) | done |
| 2 | Static canvas rendering | done |
| 3 | Interaction: place, move, wire, delete, undo | done |
| 4 | Tester panel + win detection | done |
| 5 | Animation catalogue | not started |
| 6 | Levels, scoring, persistence | done |
| 7 | Screens, responsive, accessibility | done |
| 8 | Test gaps, docs, ship | not started |

Phase 5 (the animation catalogue) is the one gap: the game is fully playable
without it, so it was deferred rather than blocking play.

## Playing it

Tap a gate in the bottom bar to pick it up, then tap the board to drop it.
Tap an output dot (right of a component), then an input dot (left) to wire
them. Tap an input pin to flip it. Long-press a gate to drag it; tap a gate or
wire and hit the bin to remove it. The status bar above the board opens the
truth table.

## Running it

```bash
flutter pub get
flutter run -d chrome          # web
flutter run                    # attached device / emulator
```

## Checks

```bash
flutter analyze                # must be clean
flutter test                   # unit + widget
```

## Regenerating the app icon

```bash
python tool/generate_icon.py   # draws the NAND mark
dart run flutter_launcher_icons # fans it out to Android / iOS / web
```

## Layout

```
lib/
  core/          theme tokens, canvas + animation constants, Result type
  domain/        PURE DART - models and the simulation engine, no Flutter
  data/          level definitions, reference functions, persistence
  application/   Riverpod controllers (from Phase 3)
  presentation/  screens, canvas, widgets, animations
```

Dependency direction is `presentation -> application -> data -> domain`, and
`domain` imports nothing but Dart. A test enforces that.

## The engine

`domain/engine/` is a pure combinational simulator:

- **Three-valued logic.** An unwired input port is `floating` (`X`), not a
  silent `0`. A dominating value still wins: `AND(0, X)` is `0`, because no
  value of the floating input could change the answer.
- **Topological evaluation.** `Simulator.evaluate` sorts components so every
  driver is computed before its consumers, and returns that order — the
  signal-flow animation replays it so players watch computation propagate.
- **Cycles are refused, not survived.** The MVP is combinational; a feedback
  loop is reported with the offending wires rather than hanging.
- **`WinChecker.check`** runs every input combination and returns a per-row
  diff, so the tester can highlight exactly which rows fail.

Every level's truth table is verified against an independent reference
function, and every level has a reference solution that must solve it within
par — a par that is quietly impossible fails the suite.

From stage 14 the tables and pars are generated rather than typed. `dart run
tool/generate_levels.dart > lib/data/levels/levels_data.dart` expands each
table from its reference function and sets par to the gate count of a
solution synthesized from that level's own palette, so par and the reference
solution can never drift apart.

## Docs

The full specification (`CLAUDE.md`, `BUILD_PROMPT.md`, `DESIGN.md`) lives in
`docs/`, which is intentionally untracked. Deviations from it are recorded in
[DECISIONS.md](DECISIONS.md).
