import '../models/ascii_art_config.dart';

/// Compiler service for generating FFmpeg video filters for ASCII terminal
/// and retro matrix character texturization.
class AsciiArtCompilerService {
  const AsciiArtCompilerService();

  /// Static convenience method for FFmpeg command builder
  static String compileFilter(
    AsciiArtConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    return const AsciiArtCompilerService().compile(config);
  }

  /// Compiles FFmpeg video filter string for the given [AsciiArtConfig].
  /// Returns empty string if disabled.
  String compile(AsciiArtConfig config) {
    if (!config.isEnabled) return '';

    final cell = config.cellSize.clamp(4, 20);
    final contrast = config.contrast.clamp(0.5, 2.5).toStringAsFixed(2);
    final filters = <String>[];

    // 1. Pixel grid block quantization (cell downsampling + nearest-neighbor upscaling)
    filters.add('scale=iw/$cell:ih/$cell:flags=neighbor');
    filters.add('scale=iw*$cell:ih*$cell:flags=neighbor');

    // 2. Contrast adjustment
    filters.add('eq=contrast=$contrast:brightness=0.02');

    // 3. Optional inversion
    if (config.isInverted) {
      filters.add('negate');
    }

    // 4. Mode-specific terminal color mapping
    switch (config.mode) {
      case AsciiArtMode.greenPhosphor:
        // Grayscale conversion then green phosphor tint
        filters.add('format=gray');
        filters.add('colorchannelmixer=rr=0:rg=0.95:rb=0:gg=0.95:gb=0:br=0:bg=0.95:bb=0');
        break;

      case AsciiArtMode.amberCathode:
        // Amber phosphor tint (high red, medium green, negligible blue)
        filters.add('format=gray');
        filters.add('colorchannelmixer=rr=1.0:rg=0.68:rb=0.08:gg=0.68:gb=0.08:br=0.08:bg=0.08:bb=0.08');
        break;

      case AsciiArtMode.cyberpunkNeon:
        // Electric cyan and magenta dual-tone boost
        filters.add('colorchannelmixer=rr=0.9:rg=0.1:rb=0.8:gg=0.2:gb=0.9:br=0.8:bg=0.9:bb=1.0');
        break;

      case AsciiArtMode.matrixColor:
        // Keep full chromatic colors with saturation boost for vivid ANSI look
        filters.add('eq=saturation=1.45');
        break;

      case AsciiArtMode.monochromePaper:
        // Crisp high-contrast black-on-white terminal paper
        filters.add('format=gray');
        filters.add('eq=contrast=1.6:brightness=0.08');
        break;
    }

    // 5. Draw terminal character cell boundaries raster
    filters.add('drawgrid=w=$cell:h=$cell:t=1:color=black@0.65');

    // 6. Optional phosphor glow bloom if enabled
    if (config.glyphGlow > 0.25) {
      filters.add('unsharp=lx=5:ly=5:la=0.65');
    }

    return filters.join(',');
  }

  /// Returns user-facing badge label for the active mode.
  String getBadgeLabel(AsciiArtConfig config) {
    if (!config.isEnabled) return '';
    return '📟 ${config.mode.label.toUpperCase()}';
  }
}
