import '../models/luma_key_config.dart';

/// Compiles luminance transparency keying, silhouette extraction, and alpha masking
/// into deterministic FFmpeg video filtergraphs.
class LumaKeyCompilerService {
  /// Compiles the complete FFmpeg video filter for luma keying.
  static String compileFilter(
    LumaKeyConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];
    filters.add('format=yuva420p');

    final thresh = config.threshold.clamp(0.01, 0.99).toStringAsFixed(2);
    final tol = config.tolerance.clamp(0.01, 0.50).toStringAsFixed(2);
    final soft = (config.tolerance * 0.8).clamp(0.01, 0.40).toStringAsFixed(2);

    switch (config.mode) {
      case LumaKeyMode.darkSilhouette:
        if (config.invert) {
          filters.add('negate=components=1');
          filters.add('lumakey=threshold=$thresh:tolerance=$tol:softness=$soft');
          filters.add('negate=components=1');
        } else {
          filters.add('lumakey=threshold=$thresh:tolerance=$tol:softness=$soft');
        }
        break;

      case LumaKeyMode.brightSpecular:
        final invThresh = (1.0 - config.threshold).clamp(0.05, 0.95).toStringAsFixed(2);
        filters.add('negate=components=1');
        filters.add('lumakey=threshold=$invThresh:tolerance=$tol:softness=$soft');
        filters.add('negate=components=1');
        break;

      case LumaKeyMode.midtonesOnly:
        filters.add('lumakey=threshold=0.15:tolerance=$tol:softness=$soft');
        break;

      case LumaKeyMode.highContrastLuma:
        filters.add('lumakey=threshold=$thresh:tolerance=0.01:softness=0.01');
        break;

      case LumaKeyMode.softThresholdGradient:
        filters.add('lumakey=threshold=$thresh:tolerance=$tol:softness=0.35');
        break;
    }

    if (config.opacity < 0.99) {
      final op = config.opacity.clamp(0.1, 1.0).toStringAsFixed(2);
      filters.add('colorchannelmixer=aa=$op');
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getLumaKeyBadge(LumaKeyConfig config) {
    if (!config.isActive) return '';
    return '✂️ LUMA KEY: ${config.mode.displayName.toUpperCase()} (${(config.threshold * 100).round()}% THRESH)';
  }
}
