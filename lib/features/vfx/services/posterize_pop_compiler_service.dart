import '../models/posterize_pop_config.dart';

/// Compiles threshold posterization and pop art chromatic styling into deterministic FFmpeg filtergraphs.
class PosterizePopCompilerService {
  /// Compiles the complete FFmpeg video filter for color quantization, pop art tinting, and comic ink contours.
  static String compileFilter(
    PosterizePopConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final levels = config.colorLevels.clamp(2, 16);
    final step = (255.0 / (levels - 1)).round().clamp(16, 255);

    // 1. Channel quantization stepping (Posterize effect)
    filters.add("lutrgb=r='round(val/$step)*$step':g='round(val/$step)*$step':b='round(val/$step)*$step'");

    // 2. Mode-specific artistic color mapping
    switch (config.mode) {
      case PosterizePopMode.warholPopArt:
        final sat = config.saturationBoost.clamp(1.0, 2.5).toStringAsFixed(2);
        final cont = config.contrast.clamp(1.0, 2.0).toStringAsFixed(2);
        filters.add('hue=h=45:s=$sat');
        filters.add('eq=contrast=$cont');
        break;

      case PosterizePopMode.comicBookInk:
        final cont = (config.contrast * 1.1).clamp(1.1, 2.0).toStringAsFixed(2);
        filters.add('eq=contrast=$cont:brightness=0.02');
        break;

      case PosterizePopMode.cyberpunkDuotone:
        filters.add('colorchannelmixer=rr=0.85:rg=0.10:rb=0.20:br=0.15:bg=0.75:bb=0.95');
        final sat = config.saturationBoost.clamp(1.0, 2.5).toStringAsFixed(2);
        filters.add('hue=s=$sat');
        break;

      case PosterizePopMode.retro8BitPoster:
        final sat = config.saturationBoost.clamp(1.0, 2.0).toStringAsFixed(2);
        filters.add('eq=saturation=$sat:contrast=1.15');
        break;

      case PosterizePopMode.monochromeNoir:
        final cont = (config.contrast * 1.25).clamp(1.2, 2.2).toStringAsFixed(2);
        filters.add('hue=s=0');
        filters.add('eq=contrast=$cont');
        break;
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getPosterizePopBadge(PosterizePopConfig config) {
    if (!config.isActive) return '';
    return '🎨 POSTERIZE POP: ${config.mode.displayName.toUpperCase()} (${config.colorLevels} LEVELS)';
  }
}
