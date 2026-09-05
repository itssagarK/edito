import '../models/character_highlight_config.dart';

class CharacterHighlightCompilerService {
  /// Compiles CharacterHighlightConfig into FFmpeg video filter chain
  static String generateFFmpegFilter(
    CharacterHighlightConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isEnabled) return '';

    final filters = <String>[];
    final cx = config.characterCenterX.toStringAsFixed(2);
    final cy = config.characterCenterY.toStringAsFixed(2);
    final dim = config.backgroundDimming.clamp(0.1, 1.0);

    // Calculate background color RGB shifts
    final bgR = ((config.backgroundColor >> 16) & 0xFF) / 255.0;
    final bgG = ((config.backgroundColor >> 8) & 0xFF) / 255.0;
    final bgB = (config.backgroundColor & 0xFF) / 255.0;

    final rm = ((bgR - 0.5) * dim * 0.7).clamp(-1.0, 1.0).toStringAsFixed(2);
    final gm = ((bgG - 0.5) * dim * 0.7).clamp(-1.0, 1.0).toStringAsFixed(2);
    final bm = ((bgB - 0.5) * dim * 0.7).clamp(-1.0, 1.0).toStringAsFixed(2);

    switch (config.mode) {
      case CharacterHighlightMode.spotlight:
        // Spotlight vignette centered on the character
        final angle = (dim * 1.15).clamp(0.2, 1.5).toStringAsFixed(2);
        filters.add('vignette=angle=$angle:x0=w*$cx:y0=h*$cy');
        if (config.backgroundColor != 0xFF141419) {
          filters.add('colorbalance=rm=$rm:gm=$gm:bm=$bm');
        }
        break;

      case CharacterHighlightMode.neonAura:
        // High contrast vibrance boost for character + colored spotlight
        final contrast = (1.0 + (0.20 * config.highlightIntensity)).toStringAsFixed(2);
        filters.add('eq=contrast=$contrast:saturation=1.25');
        final angle = (dim * 1.25).clamp(0.2, 1.5).toStringAsFixed(2);
        filters.add('vignette=angle=$angle:x0=w*$cx:y0=h*$cy');
        filters.add('colorbalance=rm=$rm:gm=$gm:bm=$bm');
        break;

      case CharacterHighlightMode.bwBackground:
        // Background desaturation + character focus
        final sat = (1.0 - (dim * 0.75)).clamp(0.1, 1.0).toStringAsFixed(2);
        final contrast = (1.0 + (0.15 * config.highlightIntensity)).toStringAsFixed(2);
        filters.add('eq=contrast=$contrast:saturation=$sat');
        final angle = (dim * 1.30).clamp(0.2, 1.5).toStringAsFixed(2);
        filters.add('vignette=angle=$angle:x0=w*$cx:y0=h*$cy');
        break;

      case CharacterHighlightMode.solidBgWash:
        // Color balance wash + spotlight cutout
        final angle = (dim * 1.20).clamp(0.2, 1.5).toStringAsFixed(2);
        filters.add('vignette=angle=$angle:x0=w*$cx:y0=h*$cy');
        filters.add('colorbalance=rm=$rm:gm=$gm:bm=$bm');
        break;
    }

    return filters.join(',');
  }

  /// Returns user-facing badge label for preview viewport HUD
  static String getHighlightBadge(CharacterHighlightConfig config) {
    if (!config.isEnabled) return '';
    final bgHex = config.backgroundColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    switch (config.mode) {
      case CharacterHighlightMode.spotlight:
        return '🌟 CHARACTER SPOTLIGHT (BG: #$bgHex)';
      case CharacterHighlightMode.neonAura:
        return '⚡ NEON AURA GLOW (BG: #$bgHex)';
      case CharacterHighlightMode.bwBackground:
        return '🎭 B&W BACKGROUND (POP)';
      case CharacterHighlightMode.solidBgWash:
        return '🎨 BG COLOR (#$bgHex)';
    }
  }
}
