import '../models/matrix_rain_config.dart';

/// Compiles matrix digital code rain, cyber glyph streams, and falling data streams
/// into deterministic FFmpeg video filtergraphs.
class MatrixRainCompilerService {
  /// Compiles the complete FFmpeg video filter for matrix code rain styling.
  static String compileFilter(
    MatrixRainConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];

    // 1. Vertical data rain column grid lines
    final colSpacing = ((1.0 - config.density * 0.5) * 24).round().clamp(10, 40);
    filters.add('drawgrid=w=$colSpacing:h=0:t=1:c=white@0.15');

    // 2. Scanline grid to mimic terminal raster
    filters.add('drawgrid=w=0:h=4:t=1:c=black@0.25');

    // 3. Mode chromatic tinting
    switch (config.mode) {
      case MatrixRainMode.classicPhosphorGreen:
        filters.add('colorchannelmixer=rr=0.10:rg=0.15:rb=0.05:gr=0.10:gg=1.35:gb=0.15:br=0.05:bg=0.15:bb=0.10');
        filters.add('hue=h=120:s=1.60');
        break;

      case MatrixRainMode.cyberpunkNeonPink:
        filters.add('colorchannelmixer=rr=1.30:rg=0.10:rb=0.30:gr=0.20:gg=0.25:gb=0.40:br=0.80:bg=0.15:bb=1.20');
        filters.add('hue=h=310:s=1.75');
        break;

      case MatrixRainMode.quantumCyanData:
        filters.add('colorchannelmixer=rr=0.10:rg=0.15:rb=0.20:gr=0.15:gg=1.10:gb=0.40:br=0.20:bg=0.50:bb=1.40');
        filters.add('hue=h=190:s=1.80');
        break;

      case MatrixRainMode.goldenAsciiGold:
        filters.add('colorchannelmixer=rr=1.35:rg=0.30:rb=0.05:gr=0.85:gg=1.05:gb=0.10:br=0.10:bg=0.15:bb=0.10');
        filters.add('hue=h=45:s=1.65');
        break;

      case MatrixRainMode.ghostMonochrome:
        filters.add('hue=s=0');
        filters.add('eq=contrast=1.35:brightness=0.04');
        break;
    }

    // 4. Glow diffusion if enabled
    if (config.glyphGlow > 0.5) {
      filters.add('unsharp=5:5:0.8:3:3:0.4');
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getMatrixRainBadge(MatrixRainConfig config) {
    if (!config.isActive) return '';
    return '💻 MATRIX RAIN: ${config.mode.displayName.toUpperCase()} (${(config.density * 100).round()}% DENSITY)';
  }
}
