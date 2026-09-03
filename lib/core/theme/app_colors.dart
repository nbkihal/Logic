import 'package:flutter/material.dart';

/// A complete colour system for the app, swappable at runtime.
///
/// Caldera is the original — see `DESIGN.md`: three chromatic tones only
/// against warm monochrome greys. The others keep the same *structure* (one
/// aggressive accent, one secondary, one highlight, two surfaces, one ink) so
/// every screen keeps its hierarchy whichever one is chosen. Anything derived
/// — hairlines, muted text, the signal bloom — is computed from those, so a
/// new palette is a dozen colours and nothing else.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.id,
    required this.name,
    required this.blurb,
    required this.brightness,
    required this.ember,
    required this.plasmaViolet,
    required this.sulfur,
    required this.limestone,
    required this.pumice,
    required this.obsidian,
    required this.chalk,
    required this.signalLow,
    required this.signalFloating,
  });

  /// Stable key, persisted in settings.
  final String id;

  /// Shown in the theme picker.
  final String name;
  final String blurb;

  final Brightness brightness;

  /// Primary action buttons, featured surfaces — the only aggressive accent,
  /// and the colour a live `1` travels in.
  final Color ember;

  /// A single accent surface. Never used for controls.
  final Color plasmaViolet;

  /// Tag and category badge backgrounds; also the solved-level card.
  final Color sulfur;

  /// Card surfaces, content blocks, secondary button fills.
  final Color limestone;

  /// Page canvas — the dominant background.
  final Color pumice;

  /// Primary text, headings, borders.
  final Color obsidian;

  /// Text on an accent fill.
  final Color chalk;

  /// Logic low (0): de-energized.
  final Color signalLow;

  /// Floating (X): rendered dashed as well as dimmed.
  final Color signalFloating;

  // --- Derived. Opacity of the above only, never a new hue. ---

  /// Hairline rules and dotted dividers.
  Color get hairline => obsidian.withValues(alpha: 0.10);

  /// Muted/secondary text.
  Color get obsidianMuted => obsidian.withValues(alpha: 0.60);

  /// Disabled/locked surfaces.
  Color get obsidianFaint => obsidian.withValues(alpha: 0.20);

  /// Logic high (1).
  Color get signalHigh => ember;

  /// Glow halo around an energized lamp.
  Color get bloom => ember.withValues(alpha: 0.40);

  /// Cycle / error emphasis.
  Color get warning => sulfur;

  bool get isDark => brightness == Brightness.dark;

  @override
  AppPalette copyWith({
    String? id,
    String? name,
    String? blurb,
    Brightness? brightness,
    Color? ember,
    Color? plasmaViolet,
    Color? sulfur,
    Color? limestone,
    Color? pumice,
    Color? obsidian,
    Color? chalk,
    Color? signalLow,
    Color? signalFloating,
  }) =>
      AppPalette(
        id: id ?? this.id,
        name: name ?? this.name,
        blurb: blurb ?? this.blurb,
        brightness: brightness ?? this.brightness,
        ember: ember ?? this.ember,
        plasmaViolet: plasmaViolet ?? this.plasmaViolet,
        sulfur: sulfur ?? this.sulfur,
        limestone: limestone ?? this.limestone,
        pumice: pumice ?? this.pumice,
        obsidian: obsidian ?? this.obsidian,
        chalk: chalk ?? this.chalk,
        signalLow: signalLow ?? this.signalLow,
        signalFloating: signalFloating ?? this.signalFloating,
      );

  /// Cross-fades one palette into another, so switching themes is a sweep
  /// rather than a jump cut.
  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      id: t < 0.5 ? id : other.id,
      name: t < 0.5 ? name : other.name,
      blurb: t < 0.5 ? blurb : other.blurb,
      brightness: t < 0.5 ? brightness : other.brightness,
      ember: mix(ember, other.ember),
      plasmaViolet: mix(plasmaViolet, other.plasmaViolet),
      sulfur: mix(sulfur, other.sulfur),
      limestone: mix(limestone, other.limestone),
      pumice: mix(pumice, other.pumice),
      obsidian: mix(obsidian, other.obsidian),
      chalk: mix(chalk, other.chalk),
      signalLow: mix(signalLow, other.signalLow),
      signalFloating: mix(signalFloating, other.signalFloating),
    );
  }

  /// The original: Ember on warm greys.
  static const caldera = AppPalette(
    id: 'caldera',
    name: 'Caldera',
    blurb: 'Ember on warm stone. The original.',
    brightness: Brightness.light,
    ember: Color(0xFFFC5000),
    plasmaViolet: Color(0xFF524AE9),
    sulfur: Color(0xFFF5F28E),
    limestone: Color(0xFFF7F6F2),
    pumice: Color(0xFFE2E2DF),
    obsidian: Color(0xFF070607),
    chalk: Color(0xFFFFFFFF),
    signalLow: Color(0xFF3A3739),
    signalFloating: Color(0xFF9A9793),
  );

  /// Lights-off: the same board, read as a circuit on a bench at night.
  static const midnight = AppPalette(
    id: 'midnight',
    name: 'Midnight',
    blurb: 'Lights off. Live wires glow.',
    brightness: Brightness.dark,
    ember: Color(0xFFFF6B2C),
    plasmaViolet: Color(0xFF8B85FF),
    sulfur: Color(0xFFE9E36B),
    limestone: Color(0xFF1D1F24),
    pumice: Color(0xFF121316),
    obsidian: Color(0xFFF2F1EE),
    chalk: Color(0xFF0B0C0E),
    signalLow: Color(0xFF4A4E57),
    signalFloating: Color(0xFF6E7480),
  );

  /// Drafting-table blue, with a cyan signal.
  static const blueprint = AppPalette(
    id: 'blueprint',
    name: 'Blueprint',
    blurb: 'Drafting ink and a cyan current.',
    brightness: Brightness.dark,
    ember: Color(0xFF35D0E0),
    plasmaViolet: Color(0xFF7C9CFF),
    sulfur: Color(0xFFFFD166),
    limestone: Color(0xFF143047),
    pumice: Color(0xFF0E2233),
    obsidian: Color(0xFFE6F1FA),
    chalk: Color(0xFF06131E),
    signalLow: Color(0xFF2C4257),
    signalFloating: Color(0xFF5A7690),
  );

  /// Paper and moss: the quiet one.
  static const orchard = AppPalette(
    id: 'orchard',
    name: 'Orchard',
    blurb: 'Paper and moss. The quiet one.',
    brightness: Brightness.light,
    ember: Color(0xFF1F8A5B),
    plasmaViolet: Color(0xFF6C4BB6),
    sulfur: Color(0xFFF3E08A),
    limestone: Color(0xFFF6F9F3),
    pumice: Color(0xFFE7EDE3),
    obsidian: Color(0xFF10231A),
    chalk: Color(0xFFFFFFFF),
    signalLow: Color(0xFF35473D),
    signalFloating: Color(0xFF8FA096),
  );

  /// Every palette the picker offers, in display order.
  static const all = [caldera, midnight, blueprint, orchard];

  static AppPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => caldera);
}

/// `context.colors.ember` — the active palette, wherever you are in the tree.
extension PaletteAccess on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.caldera;
}
