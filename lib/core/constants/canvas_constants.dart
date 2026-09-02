/// Geometry of the circuit board. Logical grid units map to pixels only here
/// and in the presentation layer — never in `domain/`.
abstract final class CanvasConstants {
  /// Side of one grid cell, in world pixels at zoom 1.0.
  static const gridCell = 32.0;

  /// Components occupy a whole number of cells.
  static const componentWidthCells = 3;
  static const componentHeightCells = 2;

  /// Visual radius of a port dot.
  static const portRadius = 6.0;

  /// Enlarged hit radius so ports clear the 44px touch target.
  static const portHitRadius = 22.0;

  /// Wire stroke width at zoom 1.0.
  static const wireStroke = 3.0;

  /// Bezier control-point reach, as a fraction of the horizontal span.
  static const wireCurvature = 0.45;

  static const minZoom = 0.4;
  static const maxZoom = 2.5;
  static const initialZoom = 1.0;

  /// Padding kept around content when fitting the view to the circuit.
  static const fitPadding = 64.0;

  /// The board is a fixed logical world, wide enough for every level with
  /// room to lay gates out loosely.
  static const worldCellsWide = 32;
  static const worldCellsHigh = 20;

  /// Level fixtures are centred on grid row 0, so grid coordinates go
  /// negative. This origin shifts the whole world into positive pixels.
  static const originCellX = 1;
  static const originCellY = 10;

  static const worldWidth = worldCellsWide * gridCell;
  static const worldHeight = worldCellsHigh * gridCell;

  /// Component footprint in world pixels.
  static const componentWidth = componentWidthCells * gridCell;
  static const componentHeight = componentHeightCells * gridCell;

  /// Undo/redo history depth (CLAUDE.md §10).
  static const undoStackLimit = 50;
}
