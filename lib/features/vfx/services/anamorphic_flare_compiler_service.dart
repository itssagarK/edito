import '../models/anamorphic_flare_config.dart';

class AnamorphicFlareCompilerService {
  /// Compiles deterministic FFmpeg filters for cinematic horizontal anamorphic streak flare bloom
  static List<String> generateFFmpegFilters(AnamorphicFlareConfig config) {
    if (!config.isActive) return [];

    final filters = <String>[];

    // 1. Color grading tint matrix for anamorphic glass reflections
    final tintFilter = config.tint.ffmpegMatrix;
    if (tintFilter.isNotEmpty) {
      filters.add(tintFilter);
    }

    // 2. Anamorphic cylindrical lens horizontal bloom stretch
    // Stretches sigma horizontally while keeping vertical sigma compact
    final sigmaH = (config.streakLength * 8.0 * config.intensity).clamp(3.0, 80.0).toStringAsFixed(1);
    final sigmaV = (config.flareThickness * 1.5 * config.intensity).clamp(0.5, 10.0).toStringAsFixed(1);
    filters.add('gblur=sigma_h=$sigmaH:sigma_v=$sigmaV:steps=2');

    // 3. Highlight luminance boost and contrast curves
    final thresh = config.threshold.clamp(0.5, 0.95).toStringAsFixed(2);
    filters.add("curves=all='0/0 $thresh/0.05 1/1'");

    return filters;
  }

  /// HUD status badge for active anamorphic flare
  static String getFlareBadge(AnamorphicFlareConfig config) {
    if (!config.isActive) return '';
    final spikes = config.starburstSpikes > 0 ? ' • ${config.starburstSpikes}pt Star' : '';
    return '✨ ANAMORPHIC FLARE (${config.tint.label}$spikes)';
  }
}
