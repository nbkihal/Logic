/// Caldera spacing and radius scale. Density: comfortable.
abstract final class AppSpacing {
  static const x4 = 4.0;
  static const x8 = 8.0;
  static const x12 = 12.0;
  static const x16 = 16.0;
  static const x20 = 20.0;
  static const x24 = 24.0;
  static const x32 = 32.0;
  static const x40 = 40.0;
  static const x48 = 48.0;
  static const x56 = 56.0;
  static const x64 = 64.0;
  static const x80 = 80.0;

  /// Padding inside a card or content block.
  static const cardPadding = x40;

  /// Gap between major page sections.
  static const sectionGap = x80;

  /// Gap between sibling elements.
  static const elementGap = x16;

  /// Page content max width.
  static const pageMaxWidth = 1280.0;
}

/// The triple-radius system: pills, cards, inputs. Never low-radius rectangles.
abstract final class AppRadii {
  /// Buttons, tags, nav containers, small interactive elements.
  static const pill = 800.0;

  /// Cards, content blocks, non-pill buttons.
  static const card = 40.0;

  /// Text inputs.
  static const input = 100.0;

  /// Medium surfaces (e.g. inner panels).
  static const medium = 20.0;

  /// Small chips and canvas components.
  static const small = 16.0;
}
