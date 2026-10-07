import '../models/film_halation_config.dart';

class FilmHalationCompilerService {
  /// Compiles deterministic FFmpeg filters for authentic 35mm film halation red emulsion scatter
  static List<String> generateFFmpegFilters(FilmHalationConfig config) {
    if (!config.isActive) return [];

    final filters = <String>[];

    // 1. Photochemical red emulsion color matrix
    final matrixFilter = config.hue.ffmpegMatrix;
    if (matrixFilter.isNotEmpty) {
      filters.add(matrixFilter);
    }

    // 2. High-contrast edge isolation & shadow compression curves
    final thresh = config.threshold.clamp(0.60, 0.95).toStringAsFixed(2);
    filters.add("curves=all='0/0 $thresh/0.04 1/1':r='0/0.08 1/1'");

    // 3. Emulsion backscatter diffusion blur
    final sigma = (config.spreadRadius * config.intensity * 0.4).clamp(1.0, 25.0).toStringAsFixed(1);
    filters.add('gblur=sigma=$sigma:steps=2');

    return filters;
  }

  /// HUD status badge for active 35mm film halation
  static String getHalationBadge(FilmHalationConfig config) {
    if (!config.isActive) return '';
    return '🎞️ HALATION (${config.hue.label} • ${(config.intensity * 100).toInt()}%)';
  }
}
